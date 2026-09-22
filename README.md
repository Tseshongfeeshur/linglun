# 伶伦

伶伦是一款使用 Flutter 开发、以 Linux 桌面为当前目标的本地音乐播放器。

当前基础版本已经包含本地曲库扫描、音频元数据和封面读取、外挂/内嵌歌词解析、
ReplayGain 音量均衡、参数化 EQ、Bass 增强、Crossfeed、播放次数统计、年度播放
汇总，以及可拖动的圆形悬浮播放器。复杂的 HRTF、SOFA 和原生 DSP 后端保留为后续
阶段，不会在 Flutter 层用未经验证的近似算法代替。

## 开发环境

- Flutter 3.47.5
- Dart 3.13.4

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 目录结构

- `lib/src/features/library`：曲库扫描、元数据、歌词来源和年度统计。
- `lib/src/features/library/presentation/collection_pages.dart`：专辑、艺术家和当前队列浏览。
- `lib/src/features/player`：播放状态、歌词领域模型、音频处理设置和悬浮播放器。
- `lib/src/core/database`：Drift 数据库、曲库索引、播放事件和应用设置。
- `docs/audio-processing.md`：音频处理链路和后续 DSP 接入边界。
