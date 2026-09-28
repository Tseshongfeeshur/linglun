# 播放页流光背景

## 状态

已实现第一版，Linux 使用 FFmpeg、Android 使用系统 MediaExtractor/MediaCodec 在播放时按需生成相同语义的 PCM 低频能量包络。播放页只使用 Isolation 四色程序化背景，未移植 Mesh 或 Pixi。

## 来源与许可证

- 流体结构、调色板用途和参数语义参考仓库内 `TEMP/SPlayer-Next`。
- Isolation 背景接口和 GLSL 实现参考 `TEMP/applemusic-like-lyrics` 的 `0.6.0` 版本。
- AMLL Core 为 AGPL-3.0-only；伶伦项目同样使用 AGPL-3.0-only，本项目使用独立 Dart/Flutter 实现，没有复制 JavaScript 运行时代码或资源。
- 封面颜色采样采用 64 像素级别、中心加权、边缘忽略和四色候选筛选逻辑；具体实现位于 `cover_analysis.dart`。

## 数据与设置

- `LibraryTracks.coverColor` 保存封面主色。
- `LibraryTracks.fluidPaletteJson` 保存四种流体颜色。
- `LibraryTracks.beatEnvelopeJson` 保存首次播放时生成的低频能量序列；扫描只复用未修改文件已有的数据。
- Linux 将音频解码为单声道 200 Hz `f32le` PCM，Android 使用原生音频解码器输出 PCM；两端都按 50 ms 窗口计算 RMS 与 Peak，并保存为 20 Hz 包络。
- 数据库 schema 10 增加上述视觉分析字段，损坏数据只会触发视觉回退。
- 播放页设置使用现有 `AppSettings` 表，键为 `visual.playbackBackground.v1`。
- 背景设置包含流动速度、动画帧率、暂停时冻结、背景跳动和跟随封面主色；渲染尺寸固定为 1.0。

## 渲染行为

- Isolation shader 使用四种封面颜色进行流体混合，并以 OkLab 风格的平滑视觉过渡为目标。
- 曲目切换时调色板在约 1 秒内过渡。
- 渲染缩放改变 shader 实际绘制尺寸；帧率限制 ticker 更新频率；流动速度改变模拟时间推进。
- 暂停时冻结开启后停止时间推进；关闭时暂停背景保持静态画面。
- 背景跳动使用播放期间按需生成的节拍序列，不依赖播放时实时 FFT。
- 没有 `BeatEnvelope` 的歌曲先开始播放，再在后台异步分析；分析范围以缓冲进度显示在进度条上，完成后立即驱动背景 Pulse 并增量写入数据库。
- Android 优先通过 MediaStore 对应的 `content://` URI 分析，URI 不可用时回退到文件路径；分析失败只跳过包络，不影响曲目入库和播放。
- Shader 初始化失败时降级为静态四色背景，不影响音频播放和歌词显示。

## 验证

已验证：

- `dart analyze`
- `flutter test test/amll_playback_page_test.dart`
- `flutter test test/widget_test.dart test/database_test.dart test/library_scanner_test.dart`
- `flutter test`
- `flutter build linux`
- `JAVA_HOME=/opt/android-studio/jbr ./gradlew :app:assembleDebug`

Android 真机扫描和 MediaStore URI 验收尚未完成；当前环境的 `adb` 无法启动设备守护进程。
