package com.linglun.linglun

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** 使用 Android 系统解码器生成与 Linux 扫描相同语义的 20 Hz RMS/Peak 包络。 */
internal class PcmEnvelopeAnalyzer(private val context: Context) {
    companion object {
        private const val envelopeRate = 20
        private const val analysisRate = 200
        private const val pcmFloatEncoding = 4
        private const val pcm16Encoding = 2
        private const val analysisTimeoutNanos = 120L * 1_000_000_000L
    }

    fun analyze(source: String, durationMs: Long): Map<String, Any> {
        val startedAt = System.nanoTime()
        val extractor = MediaExtractor()
        try {
            if (source.startsWith("content://")) {
                extractor.setDataSource(context, Uri.parse(source), null)
            } else {
                extractor.setDataSource(source)
            }

            var trackIndex = -1
            var format: MediaFormat? = null
            for (index in 0 until extractor.trackCount) {
                val candidate = extractor.getTrackFormat(index)
                if (candidate.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                    trackIndex = index
                    format = candidate
                    break
                }
            }
            if (trackIndex < 0 || format == null) {
                throw IllegalArgumentException("未找到音频轨道")
            }
            extractor.selectTrack(trackIndex)

            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalArgumentException("音频 MIME 类型为空")
            val decoder = MediaCodec.createDecoderByType(mime)
            try {
                decoder.configure(format, null, null, 0)
                decoder.start()

                var inputEnded = false
                var outputEnded = false
                var sampleRate = format.getIntegerOrNull(MediaFormat.KEY_SAMPLE_RATE) ?: 48000
                var channels = format.getIntegerOrNull(MediaFormat.KEY_CHANNEL_COUNT) ?: 1
                var encoding = format.getIntegerOrNull(MediaFormat.KEY_PCM_ENCODING) ?: pcm16Encoding
                val accumulator = BlockAccumulator()

                while (!outputEnded) {
                    if (System.nanoTime() - startedAt >= analysisTimeoutNanos) {
                        throw IllegalStateException("PCM 分析超时")
                    }
                    if (!inputEnded) {
                        val inputIndex = decoder.dequeueInputBuffer(10_000)
                        if (inputIndex >= 0) {
                            val inputBuffer = decoder.getInputBuffer(inputIndex)
                                ?: throw IllegalStateException("无法获取解码输入缓冲区")
                            inputBuffer.clear()
                            val sampleSize = extractor.readSampleData(inputBuffer, 0)
                            if (sampleSize < 0) {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputEnded = true
                            } else {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    sampleSize,
                                    extractor.sampleTime,
                                    0,
                                )
                                extractor.advance()
                            }
                        }
                    }

                    val info = MediaCodec.BufferInfo()
                    val outputIndex = decoder.dequeueOutputBuffer(info, 10_000)
                    when {
                        outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val outputFormat = decoder.outputFormat
                            sampleRate = outputFormat.getIntegerOrNull(MediaFormat.KEY_SAMPLE_RATE)
                                ?: sampleRate
                            channels = outputFormat.getIntegerOrNull(MediaFormat.KEY_CHANNEL_COUNT)
                                ?: channels
                            encoding = outputFormat.getIntegerOrNull(MediaFormat.KEY_PCM_ENCODING)
                                ?: encoding
                        }
                        outputIndex >= 0 -> {
                            val outputBuffer = decoder.getOutputBuffer(outputIndex)
                            val isCodecConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                            if (outputBuffer != null && info.size > 0 && !isCodecConfig) {
                                val buffer = outputBuffer.duplicate()
                                    .order(ByteOrder.LITTLE_ENDIAN)
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                accumulator.consume(
                                    buffer.slice().order(ByteOrder.LITTLE_ENDIAN),
                                    sampleRate,
                                    channels,
                                    encoding,
                                )
                            }
                            decoder.releaseOutputBuffer(outputIndex, false)
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                outputEnded = true
                            }
                        }
                    }
                }

                val values = accumulator.finish()
                if (values.isEmpty()) throw IllegalArgumentException("未产生 PCM 数据")
                return mapOf(
                    "version" to 1,
                    "durationMs" to durationMs,
                    "sampleRate" to envelopeRate,
                    "values" to values,
                )
            } finally {
                try {
                    decoder.stop()
                } catch (_: IllegalStateException) {
                    // 解码器在 configure/start 阶段失败时可能尚未进入可停止状态。
                }
                decoder.release()
            }
        } finally {
            extractor.release()
        }
    }

    private class BlockAccumulator {
        private var analysisSampleCount = 0
        private var energy = 0.0
        private var peak = 0.0
        private var resampleClock = 0
        private var resampleSum = 0.0
        private var resampleCount = 0
        private var pendingBytes = ByteArray(0)
        private val values = mutableListOf<Double>()

        fun consume(buffer: ByteBuffer, sampleRate: Int, channels: Int, encoding: Int) {
            val incoming = ByteArray(buffer.remaining())
            buffer.get(incoming)
            val bytes = if (pendingBytes.isEmpty()) {
                incoming
            } else {
                pendingBytes + incoming
            }
            pendingBytes = ByteArray(0)

            val safeRate = max(1, sampleRate)
            val safeChannels = max(1, channels)
            val bytesPerSample = if (encoding == pcmFloatEncoding) 4 else 2
            val frameBytes = safeChannels * bytesPerSample
            val completeBytes = bytes.size - bytes.size % frameBytes
            val frames = ByteBuffer.wrap(bytes, 0, completeBytes)
                .order(ByteOrder.LITTLE_ENDIAN)
            while (frames.remaining() >= frameBytes) {
                var mono = 0.0
                repeat(safeChannels) {
                    mono += if (bytesPerSample == 4) {
                        frames.getFloat().toDouble()
                    } else {
                        frames.getShort().toDouble() / 32768.0
                    }
                }
                mono /= safeChannels
                // Linux 端先通过 FFmpeg 降为 200 Hz，再以 50 ms 为窗口计算包络。
                // 这里用固定时间窗平均完成低频降采样，避免 Android 直接按原采样率
                // 统计高频能量，导致同一首歌的背景跳动幅度明显不同。
                resampleSum += mono
                resampleCount++
                resampleClock += analysisRate
                if (resampleClock >= safeRate) {
                    acceptAnalysisSample(resampleSum / resampleCount)
                    resampleClock -= safeRate
                    resampleSum = 0.0
                    resampleCount = 0
                }
            }
            if (completeBytes < bytes.size) {
                pendingBytes = bytes.copyOfRange(completeBytes, bytes.size)
            }
        }

        fun finish(): List<Double> = values

        private fun acceptAnalysisSample(sample: Double) {
            energy += sample * sample
            peak = max(peak, abs(sample))
            analysisSampleCount++
            if (analysisSampleCount < analysisRate / envelopeRate) return

            val rms = sqrt(energy / analysisSampleCount)
            values += ((rms * 0.55 + peak * 0.45) * 2.4)
                .coerceIn(0.0, 1.0)
            analysisSampleCount = 0
            energy = 0.0
            peak = 0.0
        }
    }
}

private fun MediaFormat.getIntegerOrNull(key: String): Int? =
    if (containsKey(key)) getInteger(key) else null
