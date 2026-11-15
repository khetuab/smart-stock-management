package com.tixolve.smart_stocks_ts


import android.content.Intent
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var player: MediaPlayer? = null
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.azan/native")

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val raw = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                    val items = raw.map {
                        AzanItem(
                            id = (it["id"] as Number).toInt(),
                            at = (it["at"] as Number).toLong(),
                            title = it["title"] as? String ?: "",
                            body = it["body"] as? String ?: "",
                            sound = it["sound"] as? String ?: "",
                        )
                    }
                    AzanAlarms.replaceAll(applicationContext, items)
                    result.success(items.size)
                }

                "cancelAll" -> {
                    AzanAlarms.cancelAll(applicationContext)
                    result.success(null)
                }

                "canScheduleExact" -> result.success(AzanAlarms.canExact(applicationContext))

                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
                        )
                    }
                    result.success(null)
                }

                "preview" -> {
                    startPreview(call.argument<String>("sound") ?: "")
                    result.success(null)
                }

                "stopPreview" -> {
                    stopPreview()
                    result.success(null)
                }

                "test" -> {
                    val svc = Intent(this, AzanService::class.java).apply {
                        action = AzanService.ACTION_PLAY
                        putExtra("title", call.argument<String>("title") ?: "Azan")
                        putExtra("body", call.argument<String>("body") ?: "")
                        putExtra("sound", call.argument<String>("sound") ?: "")
                    }
                    ContextCompat.startForegroundService(this, svc)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startPreview(sound: String) {
        stopPreview()
        val res = resources.getIdentifier(sound, "raw", packageName)
        if (res == 0) {
            channel.invokeMethod("previewDone", null)
            return
        }
        player = MediaPlayer.create(this, res)?.apply {
            setOnCompletionListener {
                stopPreview()
                channel.invokeMethod("previewDone", null)
            }
            start()
        }
        if (player == null) channel.invokeMethod("previewDone", null)
    }

    private fun stopPreview() {
        try { player?.stop() } catch (_: Exception) {}
        player?.release()
        player = null
    }

    override fun onStop() {
        stopPreview()
        super.onStop()
    }
}