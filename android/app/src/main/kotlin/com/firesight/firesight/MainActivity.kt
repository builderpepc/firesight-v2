package com.firesight.firesight

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipInputStream
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val kDeviceChannel = "com.firesight.firesight/device"
    private val kZipChannel = "com.firesight.firesight/zip"

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kZipChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractZip" -> {
                        val zipPath = call.argument<String>("zipPath")!!
                        val destPath = call.argument<String>("destPath")!!
                        // Run on a background thread — extraction can take minutes.
                        thread(name = "zip-extract") {
                            try {
                                extractZip(zipPath, destPath)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("EXTRACT_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Streams the ZIP entry-by-entry with a 64 KB buffer. Never loads more
    // than one decompressed entry at a time, so RAM usage stays constant
    // regardless of archive size.
    private fun extractZip(zipPath: String, destPath: String) {
        val destDir = File(destPath)
        destDir.mkdirs()
        val buf = ByteArray(65536)
        ZipInputStream(File(zipPath).inputStream().buffered(65536)).use { zip ->
            var entry = zip.nextEntry
            while (entry != null) {
                val outFile = File(destDir, entry.name)
                if (entry.isDirectory) {
                    outFile.mkdirs()
                } else {
                    outFile.parentFile?.mkdirs()
                    outFile.outputStream().buffered(65536).use { out ->
                        var n = zip.read(buf)
                        while (n != -1) {
                            out.write(buf, 0, n)
                            n = zip.read(buf)
                        }
                    }
                }
                zip.closeEntry()
                entry = zip.nextEntry
            }
        }
    }
}
