package dev.adampalinkas.flutter_volume_listener

import FlutterVolumeListenerHostApi
import android.content.Context
import android.content.IntentFilter
import android.media.AudioManager



import io.flutter.embedding.engine.plugins.FlutterPlugin

class FlutterVolumeListenerPlugin : FlutterPlugin, FlutterVolumeListenerHostApi {

  private lateinit var context : Context
  private lateinit var volumeReceiver: VolumeChangeReceiver
  private lateinit var volumeChangeHandler: VolumeChangeHandler

  // Entry point
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext

    FlutterVolumeListenerHostApi.setUp(binding.binaryMessenger, this)

    volumeChangeHandler = VolumeChangeHandler()
    VolumeChangeStreamHandler.register(binding.binaryMessenger, volumeChangeHandler)

    volumeReceiver = VolumeChangeReceiver(volumeChangeHandler, this)
    val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
    context.registerReceiver(volumeReceiver, filter)

  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    FlutterVolumeListenerHostApi.setUp(binding.binaryMessenger, null)
    volumeChangeHandler.onCancel(null)
  }

  // Convenience method to read the current volume
  fun readVolume() : Double {
    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    if (maxVolume == 0) {
      return 0.0
    }
    return currentVolume.toDouble() / maxVolume.toDouble()
  }

  // Reads the current volume and returns it to the caller on Flutter side.
  override fun getVolume(callback: (Result<Double>) -> Unit) {
    callback(Result.success(readVolume()))
  }

}
