import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:linglun/data/cover_thumbnail/cover_result.dart';
import 'package:linglun/data/utils/task_limiter.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:path_provider/path_provider.dart';

class CoverThumbnailCache {
  // 内存缓存
  final _memory = <String, CoverResult>{};
  static final _limiter = TaskLimiter(maxRunning: 2);

  String coverThumbnailKeyOf(TrackInfo track) {
    // TODO: 旧文件被更新后，旧 coverKey 命名的缓存文件需要删除
    final source =
        track.sourceKey +
        track.editTime.toString() +
        track.sizeBytes.toString();
    return md5.convert(utf8.encode(source)).toString();
  }

  Directory? _coverCacheDir;
  Future<Directory> _getCoverCacheDir() async {
    if (_coverCacheDir != null) return _coverCacheDir!;

    final cacheDir = await getApplicationCacheDirectory();
    final coverCachePath = p.join(cacheDir.path, 'covers');
    final coverCacheDir = await Directory(coverCachePath)
        .create(recursive: true);

    _coverCacheDir = coverCacheDir;
    return coverCacheDir;
  }

  Future<File> _cacheFileOf(String fileName) async {
    final dir = await _getCoverCacheDir();
    final file = File(p.join(dir.path, fileName));

    return file;
  }

  Future<File> _saveCoverToCache(String fileName, Uint8List? data) async {
    final dir = await _getCoverCacheDir();
    // TODO: 清理 .tmp 文件
    final file = File(p.join(dir.path, '$fileName.tmp'));

    if (data == null) {
      await file.writeAsString('');
    } else {
      await file.writeAsBytes(data);
    }

    return await file.rename(p.join(dir.path, fileName));
  }

  /// 大图转缩略图
  Future<Uint8List?> _toThumbnail(Uint8List? data) async {
    if (data == null) {
      return null;
    }

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(data, targetWidth: 300);
    } catch (e) {
      return null;
    }
    try {
      // 取出解码后的帧
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        // 导出为字节
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          return null;
        }

        final data = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        return data;
      } finally {
        image.dispose();
      }
    } catch (e) {
      return null;
    } finally {
      codec.dispose();
    }
  }

  /// 从文件获取缩略图
  Future<CoverResult> _createThumbnailFromTag(
    String key,
    TrackInfo track,
  ) async {
    final file = TagLibFile.open(track.uri);
    // 若读取文件失败
    if (file == null) {
      // 文件读取失败不写入缓存，因为下次重新读取可能成功
      return CoverFailed();
    }

    try {
      if (file.hasCover) {
        final data = file.coverData;
        final thumbnail = await _toThumbnail(data);
        if (thumbnail == null) {
          // 没有封面的情况下写入缓存
          await _saveCoverToCache(key, null);
          return CoverNone();
        }

        final saved = await _saveCoverToCache(key, thumbnail);
        return CoverFound(saved);
      } else {
        // 没有封面的情况下写入缓存
        await _saveCoverToCache(key, null);
        return CoverNone();
      }
    } finally {
      file.close();
    }
  }

  /// 根据 key 加载封面，用来在被调用处去重
  Future<CoverResult> _loadOrCreate(String key, TrackInfo track) async {
    // 尝试命中缓存
    final file = await _cacheFileOf(key);
    final stat = await file.stat();

    // 命中
    if (stat.type == FileSystemEntityType.file) {
      final coverSize = stat.size;
      // 若无封面，则返回空
      if (coverSize == 0) {
        // 没有封面
        return CoverNone();
      }

      // 否则返回图片文件
      return CoverFound(file);
    }

    // 未命中，读取文件并缓存，用 Limiter 节流
    return _limiter.run(() => _createThumbnailFromTag(key, track));
  }

  /// 去重
  final _tasks = <String, Future<CoverResult>>{};

  /// 获取封面并写入内存
  Future<CoverResult> _loadAndRemember(String key, TrackInfo track) async {
    try {
      final result = await _loadOrCreate(key, track);
      // 非失败才写入内存
      if (result is! CoverFailed) _memory[key] = result;
      return result;
    } finally {
      _tasks.remove(key);
    }
  }

  /// 通过缓存或者读取标签获取封面
  Future<CoverResult> getCoverThumbnail(TrackInfo track) {
    final key = coverThumbnailKeyOf(track);

    if (_tasks.containsKey(key)) return _tasks[key]!;
    return _tasks[key] = _loadAndRemember(key, track);
  }

  /// 通过读内存同步地获取已知封面
  CoverResult? peekCoverThumbnail(TrackInfo track) {
    final key = coverThumbnailKeyOf(track);
    // 查内存缓存
    return _memory[key];
  }
}
