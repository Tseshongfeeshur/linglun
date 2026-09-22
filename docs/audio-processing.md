# 音频处理设计

## 当前实现

伶伦当前使用 `media_kit` 驱动本地 `libmpv` 播放链路。音频设置由 Riverpod
状态保存，并写入 Drift 数据库的版本化设置表。当前后端支持：

- 读取曲目或专辑 ReplayGain 标签，并交给 mpv 做响度均衡；
- 预放大；
- 十段参数化均衡器，支持 peaking、low-shelf 和 high-shelf 频段；
- 低频增强；
- Crossfeed 耳机串音处理；
- 输出限幅，默认峰值上限为 `-1 dBFS`。

用户音量不由伶伦单独修改。ReplayGain 只改变播放链路中的节目增益，不能替代
系统音量，也不会改变音轨文件本身。

滤镜顺序固定为：预放大、均衡器、Bass、空间处理、限幅。增益值使用 dB，限幅
阈值转换为线性振幅后传给 `alimiter`，避免把 dB 值直接当作线性值造成错误增益。

## ReplayGain 规则

扫描器优先读取 `REPLAYGAIN_TRACK_GAIN`，缺少曲目增益时回退到
`REPLAYGAIN_ALBUM_GAIN`，并把来源模式保存到曲目模型。播放时根据设置选择
`track`、`album` 或 `no`，同时关闭 mpv 的额外 preamp，并启用削波保护。

## 后续原生 DSP

Crossfeed 和基础滤镜先使用 mpv/libavfilter，确保播放稳定和参数可解释。HRTF、
SOFA 数据、动态 Bass 谐波增强以及多声道上混暂不在 Flutter 层伪造实现；后续会
以独立原生 DSP 后端接入，保留相同的 `AudioProcessingSettings` 参数模型。

本阶段没有复制第三方项目的算法代码。若后续引入 bs2b、SOFA/HRTF 或其他开源
DSP 实现，需要在此文档记录项目、版本、许可证、改动范围和运行时依赖。
