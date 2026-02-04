package dev.adampalinkas.flutter_volume_listener

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class VolumeChangeReceiver(
  private val eventHandler: VolumeChangeHandler?,
  private val plugin: FlutterVolumeListenerPlugin
) : BroadcastReceiver() {
  private var lastVolume: Double = -1.0

  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == "android.media.VOLUME_CHANGED_ACTION") {
      val volume = plugin.getVolume()
      if (volume != lastVolume) {
        lastVolume = volume
        eventHandler?.onVolumeChangedEvent(volume)
      }
    }
  }
}
