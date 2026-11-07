package com.rchrdariza.retropod

import android.media.AudioAttributes
import android.media.SoundPool
import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// The manifest launcher activity; extends the audio service activity so
/// media notifications keep working, and hosts the click wheel sound pool
/// channel (see lib/features/device/services/click_sound_service.dart), the
/// audio visualizer FFT channel (see
/// lib/features/now_playing/services/visualizer_service.dart), and the keep
/// screen awake channel (see
/// lib/features/now_playing/services/keep_screen_on_service.dart).
class MainActivity : AudioServiceActivity() {
    private companion object {
        /// Method channel hosting the click wheel sound pool; see
        /// lib/features/device/services/click_sound_service.dart.
        const val CLICK_SOUND_CHANNEL = "retropod/click_sound"

        /// Simultaneous tick streams so rapid wheel steps overlap like the
        /// ticks of a real iPod click wheel instead of cutting each other
        /// off.
        const val MAX_CLICK_STREAMS = 4

        /// Method channel controlling the audio visualizer FFT capture; see
        /// lib/features/now_playing/services/visualizer_service.dart.
        const val VISUALIZER_CHANNEL = "retropod/visualizer"

        /// Event channel streaming raw FFT byte arrays from the audio
        /// visualizer; see lib/features/now_playing/services/visualizer_service.dart.
        const val VISUALIZER_EVENTS_CHANNEL = "retropod/visualizer_events"

        /// Method channel holding the FLAG_KEEP_SCREEN_ON window flag while
        /// the Now Playing screen is open; see
        /// lib/features/now_playing/services/keep_screen_on_service.dart.
        const val KEEP_SCREEN_ON_CHANNEL = "retropod/keep_screen_on"

        /// Log tag for the visualizer attach diagnostics.
        const val TAG = "RetropodVisualizer"
    }

    private var clickSoundPool: SoundPool? = null
    private val clickSoundLoadResults = mutableMapOf<Int, MethodChannel.Result>()

    private var visualizer: Visualizer? = null
    private var visualizerEvents: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CLICK_SOUND_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "load" -> loadClickSound(call, result)
                "play" -> playClickSound(call, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VISUALIZER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "attach" -> attachVisualizer(call, result)
                "detach" -> detachVisualizer(result)
                else -> result.notImplemented()
            }
        }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VISUALIZER_EVENTS_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    visualizerEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    visualizerEvents = null
                }
            },
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KEEP_SCREEN_ON_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> setKeepScreenOn(call, result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        releaseVisualizer()
        mainHandler.removeCallbacksAndMessages(null)
        clickSoundPool?.release()
        clickSoundPool = null
        clickSoundLoadResults.clear()
        super.onDestroy()
    }

    private fun getOrCreateClickSoundPool(): SoundPool {
        clickSoundPool?.let { return it }
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val pool = SoundPool.Builder()
            .setAudioAttributes(attributes)
            .setMaxStreams(MAX_CLICK_STREAMS)
            .build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            clickSoundLoadResults.remove(sampleId)?.let { pending ->
                if (status == 0) {
                    pending.success(sampleId)
                } else {
                    pending.error(
                        "loadFailed",
                        "SoundPool load failed with status $status",
                        null,
                    )
                }
            }
        }
        clickSoundPool = pool
        return pool
    }

    /// SoundPool decodes asynchronously, so the load result is answered
    /// from the OnLoadCompleteListener instead of right away.
    private fun loadClickSound(call: MethodCall, result: MethodChannel.Result) {
        val name: String? = call.argument<String>("name")
        val bytes: ByteArray? = call.argument<ByteArray>("bytes")
        if (name == null || bytes == null) {
            result.error("invalidArguments", "load requires name and bytes", null)
            return
        }
        val soundId = getOrCreateClickSoundPool()
            .load(clickSoundFile(name, bytes).absolutePath, 1)
        if (soundId <= 0) {
            result.error(
                "loadFailed",
                "SoundPool could not start loading $name",
                null,
            )
            return
        }
        clickSoundLoadResults[soundId] = result
    }

    /// SoundPool cannot decode in-memory bytes, so the asset payload is
    /// written to a small cache file and loaded from disk.
    private fun clickSoundFile(name: String, bytes: ByteArray): File {
        val directory = File(cacheDir, "click_sounds").apply { mkdirs() }
        val file = File(directory, "$name.wav")
        if (!file.exists() || file.length() != bytes.size.toLong()) {
            file.writeBytes(bytes)
        }
        return file
    }

    private fun playClickSound(call: MethodCall, result: MethodChannel.Result) {
        val soundId: Int? = call.argument<Int>("soundId")
        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
        val pool = clickSoundPool
        if (soundId == null || pool == null) {
            result.success(0)
            return
        }
        result.success(pool.play(soundId, volume, volume, 1, 0, 1f))
    }

    /// Attaches the android.media.audiofx.Visualizer to the player's audio
    /// session and streams typed FFT/waveform frames to Flutter. Attaching
    /// to our own session does not require the RECORD_AUDIO permission.
    private fun attachVisualizer(call: MethodCall, result: MethodChannel.Result) {
        val sessionId: Int? = call.argument<Int>("sessionId")
        if (sessionId == null) {
            result.error("invalidArguments", "attach requires sessionId", null)
            return
        }
        releaseVisualizer()
        try {
            val viz = Visualizer(sessionId)
            val captureSizeRange = Visualizer.getCaptureSizeRange()
            viz.captureSize = captureSizeRange[captureSizeRange.size - 1]
            viz.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer,
                        waveform: ByteArray,
                        samplingRate: Int,
                    ) {
                        val sink = visualizerEvents ?: return
                        val copy = waveform.copyOf()
                        mainHandler.post {
                            sink.success(
                                mapOf("type" to "wave", "data" to copy),
                            )
                        }
                    }

                    override fun onFftDataCapture(
                        visualizer: Visualizer,
                        fft: ByteArray,
                        samplingRate: Int,
                    ) {
                        val sink = visualizerEvents ?: return
                        val copy = fft.copyOf()
                        mainHandler.post {
                            sink.success(
                                mapOf("type" to "fft", "data" to copy),
                            )
                        }
                    }
                },
                Visualizer.getMaxCaptureRate(),
                true,
                true,
            )
            viz.enabled = true
            visualizer = viz
            Log.d(TAG, "Visualizer attached, session=$sessionId, captureSize=${viz.captureSize}")
            result.success(true)
        } catch (e: Exception) {
            releaseVisualizer()
            Log.e(TAG, "Visualizer attach failed, session=$sessionId", e)
            result.error("visualizerError", e.message, null)
        }
    }

    private fun detachVisualizer(result: MethodChannel.Result) {
        releaseVisualizer()
        result.success(true)
    }

    private fun releaseVisualizer() {
        visualizer?.enabled = false
        visualizer?.release()
        visualizer = null
    }

    private fun setKeepScreenOn(call: MethodCall, result: MethodChannel.Result) {
        val enable: Boolean? = call.argument<Boolean>("enable")
        if (enable == null) {
            result.error("invalidArguments", "set requires enable", null)
            return
        }
        mainHandler.post {
            if (enable) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            result.success(true)
        }
    }
}
