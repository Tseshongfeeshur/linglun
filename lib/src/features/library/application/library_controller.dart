import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/application/player_controller.dart';
import '../../player/domain/track.dart';
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

  @override
  LibraryState build() {
    return const LibraryState(
      tracks: demoTracks,
      directories: [],
      isScanning: false,
    );
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
