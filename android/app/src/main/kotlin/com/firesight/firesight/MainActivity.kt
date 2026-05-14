package com.firesight.firesight

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val kDeviceChannel = "com.firesight.firesight/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kDeviceChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTotalRamMb" -> {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val info = ActivityManager.MemoryInfo()
                        am.getMemoryInfo(info)
                        result.success((info.totalMem / (1024 * 1024)).toInt())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
