package dev.adampalinkas.flutter_volume_listener

import FlutterVolumeListenerHostApi
import android.content.Context
import android.content.IntentFilter
import android.media.AudioManager

import io.flutter.embedding.engine.plugins.FlutterPlugin

class FlutterVolumeListenerPlugin : FlutterPlugin, FlutterVolumeListenerHostApi {

  private lateinit var context : Context
  private lateinit var volumeReceiver: VolumeChangeReceiver
  private lateinit var volumeHandler: VolumeChangeHandler

  // Entry point
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext

    FlutterVolumeListenerHostApi.setUp(binding.binaryMessenger, this)

    volumeHandler = VolumeChangeHandler()
    VolumeChangeStreamHandler.register(binding.binaryMessenger, volumeHandler)

    volumeReceiver = VolumeChangeReceiver(volumeHandler, this)
    val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
    context.registerReceiver(volumeReceiver, filter)

  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    FlutterVolumeListenerHostApi.setUp(binding.binaryMessenger, null)
    volumeHandler.onCancel(null)
  }

  // Convenience method to read the current volume
  fun getVolume() : Double {
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
    callback(Result.success(getVolume()))
  }

  // This is for API Parity with iOS side where an extra trick is required to
  // read the value after resuming the app from the background.
  // On Android it does the same as 'getVolume', no difference.
  override fun getVolumeOnResume(callback: (Result<Double>) -> Unit) {
    callback(Result.success(getVolume()))
  }

}
