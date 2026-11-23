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
  String _coverKeyOf(TrackInfo track) {
    // TODO: 旧文件被更新后，旧 coverKey 命名的缓存文件需要删除
    final source =
        track.sourceKey +
        track.editTime.toString() +
        track.sizeBytes.toString();
    return md5.convert(utf8.encode(source)).toString();
  }

  Future<Directory> _getCoverCacheDir() async {
    // TODO: _getCoverCacheDir() 每次调用都要走一次平台通道，列表里每一项都会调用，应该缓存成成员变量。
    final cacheDir = await getApplicationCacheDirectory();
    final coverCachePath = p.join(cacheDir.path, 'covers');
    final coverCacheDir = await Directory(coverCachePath)
        .create(recursive: true);

    return coverCacheDir;
  }

  Future<File?> _loadCoverFromCache(String fileName) async {
    print('开始解析 $fileName');
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
    // TODO: 先尝试在内存访问

    // 尝试命中缓存
    final coverCache = await _loadCoverFromCache(_coverKeyOf(track));

    // 命中
    if (coverCache != null) {
      final coverSize = (await coverCache.stat()).size;
      // 若无封面，则返回空
      if (coverSize == 0) return null;

      // 否则返回图片文件
      return coverCache;
    }

    // 未命中，读取文件并缓存
    final file = TagLibFile.open(track.uri);
    // 若读取文件失败
    if (file == null) {
      // TODO: 在内存标记
      // 文件读取失败不写入缓存，因为下次重新读取可能成功
      return null;
    }
    try {
      if (file.hasCover) {
        final data = file.coverData;
        final thumbnail = await _makeThumbnail(data);
        if (thumbnail == null) {
          // TODO: 在内存标记
          // 没有封面的情况下写入缓存
          await _saveCoverToCache(_coverKeyOf(track), null);
          return null;
        }

        return await _saveCoverToCache(_coverKeyOf(track), thumbnail);
      } else {
        // TODO: 在内存标记
        // 没有封面的情况下写入缓存
        await _saveCoverToCache(_coverKeyOf(track), null);
        return null;
      }
    } finally {
      file.close();
    }
  }

  final _tasks = <String, Future<File?>>{};

  Future<File?> getCoverFile(TrackInfo track) {
    final key = _coverKeyOf(track);

    return _tasks.putIfAbsent(
      key,
      () => _loadOrCreate(key, track).whenComplete(() {
        _tasks.remove(key);
      }),
    );
  }
}
