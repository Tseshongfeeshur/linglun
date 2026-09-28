package com.linglun.linglun

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val requestCode = 4101
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "linglun/android_media_library")
            .setMethodCallHandler { call, result ->
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
}
