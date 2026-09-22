import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path_util;

import '../../player/application/player_controller.dart';
import '../../player/domain/track.dart';
import '../../../core/database/app_database.dart';
import '../data/library_repository.dart';
import 'library_scanner.dart';

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);

class LibraryState {
  const LibraryState({
    required this.tracks,
    required this.directories,
    required this.isScanning,
    this.error,
  });

  final List<Track> tracks;
  final List<String> directories;
  final bool isScanning;
  final String? error;

  LibraryState copyWith({
    List<Track>? tracks,
    List<String>? directories,
    bool? isScanning,
    String? error,
    bool clearError = false,
  }) {
    return LibraryState(
      tracks: tracks ?? this.tracks,
      directories: directories ?? this.directories,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class LibraryController extends Notifier<LibraryState> {
  final _scanner = LibraryScanner();
  LibraryRepository? _repository;

  @override
  LibraryState build() {
    // 数据库由进程级共享单例持有，不能在单个 Controller 销毁时关闭，
    // 否则播放器和曲库 Controller 之间会互相关闭仍在使用的连接。
    unawaited(_initialize());
    return const LibraryState(
      tracks: demoTracks,
      directories: [],
      isScanning: false,
    );
  }

  Future<void> _initialize() async {
    try {
      final database = await sharedLinglunDatabase();
      _repository = LibraryRepository(database);
      final library = await _repository!.load();
      if (library.tracks.isNotEmpty) {
        state = state.copyWith(
          tracks: library.tracks,
          directories: library.directories,
        );
        ref
            .read(playerControllerProvider.notifier)
            .replaceQueue(library.tracks);
      } else if (library.directories.isNotEmpty) {
        await scan(library.directories);
      } else {
        await scan(_defaultDirectories());
      }
    } on Object {
      // 数据库暂不可用时保留内存曲库，避免影响应用启动和测试环境。
    }
  }

  Future<void> pickDirectoryAndScan() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: '选择音乐目录');
    if (path == null || path.isEmpty) return;

    await scan([...state.directories, path]);
  }

  Future<void> scan([List<String>? directories]) async {
    final roots = _normalizeDirectories(directories ?? _defaultDirectories());
    state = state.copyWith(
      directories: roots,
      isScanning: true,
      clearError: true,
    );

    try {
      final tracks = await _scanner.scan(roots);
      state = state.copyWith(tracks: tracks, isScanning: false);
      // 即使扫描结果为空，也要同步播放器队列，避免界面曲库已经清空而播放器仍
      // 保留上一轮扫描结果。播放器内部会用示例队列维持非空状态不变量。
      ref.read(playerControllerProvider.notifier).replaceQueue(tracks);
      await _repository?.replaceLibrary(tracks: tracks, directories: roots);
    } on Object catch (error) {
      state = state.copyWith(isScanning: false, error: '扫描曲库失败：$error');
    }
  }

  List<String> _normalizeDirectories(Iterable<String> directories) {
    final normalized = <String>{};
    for (final value in directories) {
      final directory = value.trim();
      if (directory.isEmpty) continue;
      final absolute = Directory(directory).absolute;
      try {
        normalized.add(
          path_util.normalize(absolute.resolveSymbolicLinksSync()),
        );
      } on FileSystemException {
        // 目录可能暂时不存在，仍保存规范化绝对路径供后续扫描。
        normalized.add(path_util.normalize(absolute.path));
      }
    }
    return normalized.toList();
  }

  List<String> _defaultDirectories() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return const [];

    // Linux 桌面环境通常通过 user-dirs.dirs 声明 XDG 音乐目录。
    final userDirs = File('$home/.config/user-dirs.dirs');
    if (userDirs.existsSync()) {
      final line = userDirs
          .readAsLinesSync()
          .where((line) => line.trimLeft().startsWith('XDG_MUSIC_DIR='))
          .firstOrNull;
      if (line != null) {
        final match = RegExp(r'XDG_MUSIC_DIR="?([^"\n]+)"?').firstMatch(line);
        final configured = match?.group(1)?.replaceFirst(r'$HOME', home);
        if (configured != null && configured.isNotEmpty) {
          return [Directory(configured).path];
        }
      }
    }
    return [Directory('$home/Music').path];
  }
}
