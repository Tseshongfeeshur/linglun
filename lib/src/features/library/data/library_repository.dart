import '../../../core/database/app_database.dart';

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../player/domain/track.dart';
import '../../player/domain/lyrics_source.dart';
import '../../player/domain/visual_analysis.dart';

class LibraryRepository {
  LibraryRepository(this.database);

  final AppDatabase database;

  Future<({List<Track> tracks, List<String> directories})> load() async {
    final rows = await database.loadTracks();
    final directories = await database.loadDirectories();
    return (
      tracks: rows.map(_toTrack).toList(),
      directories: directories.map((row) => row.directoryPath).toList(),
    );
  }

  Future<void> replaceLibrary({
    required List<Track> tracks,
    required List<String> directories,
  }) {
    return _replaceLibrary(tracks: tracks, directories: directories);
  }

  Future<void> _replaceLibrary({
    required List<Track> tracks,
    required List<String> directories,
  }) async {
    // 扫描会重建文件索引，但播放统计必须跨扫描保留。
    final previous = {
      for (final row in await database.loadTracks()) row.id: row,
    };

    await database.replaceLibrary(
      tracks: tracks.where((track) => track.path != null).map((track) {
        final old = previous[track.id];
        return LibraryTracksCompanion.insert(
          id: track.id,
          filePath: track.path!,
          coverBytes: Value(track.coverBytes),
          title: track.title,
          artist: track.artist,
          artistsJson: Value(jsonEncode(track.artistNames)),
          album: track.album,
          durationMs: track.duration.inMilliseconds,
          coverColor: track.coverColor,
          fluidPaletteJson: Value(
            track.fluidPalette == null
                ? null
                : jsonEncode(track.fluidPalette!.toJson()),
          ),
          beatEnvelopeJson: Value(track.beatEnvelope?.encode()),
          lyrics: Value(track.lyrics),
          lyricsFormat: Value(track.lyricsFormat),
          lyricsSourcesJson: Value(
            track.lyricsSources.isEmpty
                ? null
                : jsonEncode(
                    track.lyricsSources
                        .map((source) => source.toJson())
                        .toList(),
                  ),
          ),
          metadataJson: Value(
            track.metadata.isEmpty ? null : jsonEncode(track.metadata),
          ),
          replayGainDb: Value(track.replayGainDb),
          replayGainMode: Value(track.replayGainMode),
          playCount: Value(old?.playCount ?? track.playCount),
          lastPlayedAt: Value(old?.lastPlayedAt ?? track.lastPlayedAt),
          addedAt: Value(old?.addedAt ?? track.addedAt),
          modifiedAt: Value(track.modifiedAt),
          updatedAt: DateTime.now(),
        );
      }).toList(),
      directories: directories,
    );
  }

  Track _toTrack(LibraryTrack row) {
    return Track(
      id: row.id,
      path: row.filePath,
      coverBytes: row.coverBytes,
      title: row.title,
      artist: row.artist,
      artists: _decodeArtists(row.artistsJson, row.artist),
      album: row.album,
      duration: Duration(milliseconds: row.durationMs),
      lyrics: row.lyrics,
      lyricsFormat: row.lyricsFormat,
      lyricsSources: _decodeLyricsSources(row.lyricsSourcesJson),
      metadata: _decodeMetadata(row.metadataJson),
      replayGainDb: row.replayGainDb,
      replayGainMode: row.replayGainMode,
      playCount: row.playCount,
      lastPlayedAt: row.lastPlayedAt,
      addedAt: row.addedAt,
      modifiedAt: row.modifiedAt,
      coverColor: row.coverColor,
      fluidPalette: _decodePalette(row.fluidPaletteJson),
      beatEnvelope: _decodeBeatEnvelope(row.beatEnvelopeJson),
    );
  }

  FluidPalette? _decodePalette(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return FluidPalette.fromJson(jsonDecode(value));
    } on Object {
      return null;
    }
  }

  BeatEnvelope? _decodeBeatEnvelope(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return BeatEnvelope.fromJson(jsonDecode(value));
    } on Object {
      return null;
    }
  }

  Map<String, String> _decodeMetadata(String? value) {
    if (value == null || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } on FormatException {
      // 旧版本或损坏的详情数据不应影响曲库加载。
    }
    return const {};
  }

  List<String> _decodeArtists(String? value, String fallback) {
    if (value != null && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          final artists = decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (artists.isNotEmpty) return artists;
        }
      } on FormatException {
        // 损坏的艺术家列表回退到兼容字段。
      }
    }
    return splitArtistNames(fallback);
  }

  List<LyricsSource> _decodeLyricsSources(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is Map)
              LyricsSource.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
        ];
      }
    } on FormatException {
      // 旧版本或损坏的歌词来源数据不应影响曲库加载。
    }
    return const [];
  }
}
