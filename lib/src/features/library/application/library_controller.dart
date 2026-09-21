import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  AppDatabase? _database;
  LibraryRepository? _repository;

  @override
  LibraryState build() {
    ref.onDispose(() => _database?.close());
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
      _database = database;
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
        state = state.copyWith(directories: library.directories);
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
    final roots = directories ?? _defaultDirectories();
    state = state.copyWith(
      directories: roots,
      isScanning: true,
      clearError: true,
    );

    try {
      final tracks = await _scanner.scan(roots);
      state = state.copyWith(tracks: tracks, isScanning: false);
      if (tracks.isNotEmpty) {
        ref.read(playerControllerProvider.notifier).replaceQueue(tracks);
      }
      await _repository?.replaceLibrary(tracks: tracks, directories: roots);
    } on Object catch (error) {
      state = state.copyWith(isScanning: false, error: '扫描曲库失败：$error');
    }
  }

  List<String> _defaultDirectories() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return const [];
    return [Directory('$home/Music').path];
  }
}
