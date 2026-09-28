package com.linglun.linglun

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : AudioServiceActivity() {
    private val requestCode = 4101
    private var pendingResult: MethodChannel.Result? = null
    private var mediaLibraryChannel: MethodChannel? = null
    private val cancelledPcmAnalyses = ConcurrentHashMap.newKeySet<String>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaLibraryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "linglun/android_media_library",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "cancelPcmEnvelope") {
                    val requestId = call.argument<String>("requestId")
                    if (requestId.isNullOrEmpty()) {
                        result.success(null)
                    } else {
                        cancelledPcmAnalyses.add(requestId)
                        result.success(null)
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "analyzePcmEnvelope") {
                    val source = call.argument<String>("path")
                    val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                    val requestId = call.argument<String>("requestId")
                    if (source.isNullOrEmpty() || durationMs <= 0L) {
                        result.error("invalid_source", "音频路径或时长为空", null)
                    } else if (requestId.isNullOrEmpty()) {
                        result.error("invalid_request", "PCM 分析请求标识为空", null)
                    } else {
                        analyzePcmEnvelope(source, durationMs, requestId, result)
                    }
                    return@setMethodCallHandler
                }
                if (call.method != "audioPaths") {
                    if (call.method == "uriForPath") {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.success(null)
                        } else {
                            queryAudioUri(path, result)
                        }
                    } else {
                        result.notImplemented()
                    }
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "媒体库权限请求仍在进行中", null)
                    return@setMethodCallHandler
                }
                val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_AUDIO
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                    checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED
                ) {
                    pendingResult = result
                    requestPermissions(arrayOf(permission), requestCode)
                } else {
                    queryAudioPaths(result)
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != this.requestCode) return
        val result = pendingResult ?: return
        pendingResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            queryAudioPaths(result)
        } else {
            result.success(null)
        }
    }

    private fun queryAudioPaths(result: MethodChannel.Result) {
        // MediaStore 查询可能较慢，避免阻塞 Flutter 主线程。
        Thread {
            try {
                val paths = mutableListOf<String>()
                contentResolver.query(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(MediaStore.Audio.Media.DATA),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    val pathIndex = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                    while (cursor.moveToNext()) {
                        cursor.getString(pathIndex)?.let(paths::add)
                    }
                }
                runOnUiThread { result.success(paths) }
            } catch (error: Exception) {
                runOnUiThread { result.error("media_query", "读取 Android 媒体库失败", error.message) }
            }
        }.start()
    }

    private fun queryAudioUri(path: String, result: MethodChannel.Result) {
        Thread {
            try {
                var uri: String? = null
                contentResolver.query(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(MediaStore.Audio.Media._ID),
                    "${MediaStore.Audio.Media.DATA} = ?",
                    arrayOf(path),
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(
                            cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID),
                        )
                        uri = MediaStore.Audio.Media.getContentUri(
                            "external",
                            id,
                        ).toString()
                    }
                }
                runOnUiThread { result.success(uri) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("media_uri", "查找 Android 媒体 URI 失败", error.message)
                }
            }
        }.start()
    }

    private fun analyzePcmEnvelope(
        source: String,
        durationMs: Long,
        requestId: String,
        result: MethodChannel.Result,
    ) {
        cancelledPcmAnalyses.remove(requestId)
        // 解码和分析都在工作线程执行，避免播放线程和 Flutter UI 线程被阻塞。
        Thread {
            try {
                val envelope = PcmEnvelopeAnalyzer(this).analyze(
                    source = source,
                    durationMs = durationMs,
                    isCancelled = { cancelledPcmAnalyses.contains(requestId) },
                    onProgress = { progress, offset, values ->
                        runOnUiThread {
                            if (!cancelledPcmAnalyses.contains(requestId)) {
                                mediaLibraryChannel?.invokeMethod(
                                    "pcmAnalysisProgress",
                                    mapOf(
                                        "requestId" to requestId,
                                        "progress" to progress,
                                        "offset" to offset,
                                        "values" to values,
                                    ),
                                )
                            }
                        }
                    },
                )
                runOnUiThread { result.success(envelope) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("pcm_analysis", "分析音频 PCM 失败", error.message)
                }
            } finally {
                cancelledPcmAnalyses.remove(requestId)
            }
        }.start()
    }
}
