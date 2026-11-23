import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:path_provider/path_provider.dart';

class CoverCache {
  // 内存缓存
  final _memory = <String, File?>{};
  static final _noCover = File('no_cover');
  bool isNoCover(File? file) => identical(file, _noCover);

  String _coverKeyOf(TrackInfo track) {
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

  Future<File?> _loadCoverFromCache(String fileName) async {
    final dir = await _getCoverCacheDir();
    final file = File(p.join(dir.path, fileName));
    final exist = await file.exists();

    if (exist) {
      return file;
    } else {
      return null;
    }
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

  // 大图转缩略图
  Future<Uint8List?> _makeThumbnail(Uint8List? data) async {
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

  // 根据 key 加载封面，用来在被调用处去重
  Future<File?> _loadOrCreate(String key, TrackInfo track) async {
    // 尝试命中缓存
    final coverCache = await _loadCoverFromCache(key);

    // 命中
    if (coverCache != null) {
      final coverSize = (await coverCache.stat()).size;
      // 若无封面，则返回空
      if (coverSize == 0) {
        // 没有封面的情况下写入内存
        _memory[key] = _noCover;
        return null;
      }

      // 否则返回图片文件并写入内存
      _memory[key] = coverCache;
      return coverCache;
    }

    // 未命中，读取文件并缓存
    final file = TagLibFile.open(track.uri);
    // 若读取文件失败
    if (file == null) {
      // 文件读取失败不写入缓存，因为下次重新读取可能成功
      return null;
    }
    try {
      if (file.hasCover) {
        final data = file.coverData;
        final thumbnail = await _makeThumbnail(data);
        if (thumbnail == null) {
          _memory[key] = _noCover;
          // 没有封面的情况下写入缓存
          await _saveCoverToCache(key, null);
          return null;
        }

        final saved = await _saveCoverToCache(key, thumbnail);
        _memory[key] = saved;
        return saved;
      } else {
        _memory[key] = _noCover;
        // 没有封面的情况下写入缓存
        await _saveCoverToCache(key, null);
        return null;
      }
    } finally {
      file.close();
    }
  }

  final _tasks = <String, Future<File?>>{};

  // 通过缓存或者读取标签获取封面
  Future<File?> getCoverFile(TrackInfo track) {
    final key = _coverKeyOf(track);
    return _tasks.putIfAbsent(
      key,
      () => _loadOrCreate(key, track).whenComplete(() {
        _tasks.remove(key);
      }),
    );
  }

  // 通过读内存同步地获取已知封面
  File? peekCoverFile(TrackInfo track) {
    final key = _coverKeyOf(track);
    // 查内存缓存
    if (_memory.containsKey(key)) {
      final file = _memory[key];
      return file;
    }
    return null;
  }
}
