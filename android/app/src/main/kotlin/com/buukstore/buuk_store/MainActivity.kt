package com.buukstore.buuk_store

import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var player: MediaPlayer? = null
    private var loadedPart: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "buuk_store/preview")
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "play" -> {
                        val part = requireNotNull(call.argument<Int>("part"))
                        val rate = requireNotNull(call.argument<Double>("rate")).toFloat()
                        if (loadedPart != part) {
                            stopPreview()
                            val path = FlutterInjector.instance().flutterLoader()
                                .getLookupKeyForAsset("assets/audio/part-$part.mp3")
                            val next = MediaPlayer()
                            player = next
                            next.setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                                    .build()
                            )
                            assets.openFd(path).use {
                                next.setDataSource(it.fileDescriptor, it.startOffset, it.length)
                            }
                            next.prepare()
                            next.setOnCompletionListener {
                                stopPreview()
                                channel.invokeMethod("complete", null)
                            }
                            loadedPart = part
                        }
                        player?.apply {
                            playbackParams = playbackParams.setSpeed(rate)
                            start()
                        }
                    }
                    "pause" -> player?.pause()
                    "stop" -> stopPreview()
                    "rate" -> player?.takeIf { it.isPlaying }?.apply {
                        playbackParams = playbackParams.setSpeed((call.arguments as Double).toFloat())
                    }
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                result.success(null)
            } catch (error: Exception) {
                stopPreview()
                result.error("preview_failed", error.message, null)
            }
        }
    }

    private fun stopPreview() {
        player?.release()
        player = null
        loadedPart = null
    }

    override fun onDestroy() {
        stopPreview()
        super.onDestroy()
    }
}
