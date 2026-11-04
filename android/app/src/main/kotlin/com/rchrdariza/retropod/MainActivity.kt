package com.rchrdariza.retropod

import android.media.AudioAttributes
import android.media.SoundPool
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// The manifest launcher activity; extends the audio service activity so
/// media notifications keep working, and hosts the click wheel sound pool
/// channel (see lib/features/device/services/click_sound_service.dart).
class MainActivity : AudioServiceActivity() {
    private companion object {
        /// Method channel hosting the click wheel sound pool; see
        /// lib/features/device/services/click_sound_service.dart.
        const val CLICK_SOUND_CHANNEL = "retropod/click_sound"

        /// Simultaneous tick streams so rapid wheel steps overlap like the
        /// ticks of a real iPod click wheel instead of cutting each other
        /// off.
        const val MAX_CLICK_STREAMS = 4
    }

    private var clickSoundPool: SoundPool? = null
    private val clickSoundLoadResults = mutableMapOf<Int, MethodChannel.Result>()

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
    }

    override fun onDestroy() {
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
}
