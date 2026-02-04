package dev.adampalinkas.flutter_volume_listener

import PigeonEventSink
import VolumeChangeStreamHandler

class VolumeChangeHandler : VolumeChangeStreamHandler() {

  private var eventSink: PigeonEventSink<Double>? = null

  override fun onListen(p0: Any?, sink: PigeonEventSink<Double>) {
    eventSink = sink
  }

  fun onVolumeChangedEvent(volume: Double) {
    eventSink?.success(volume)
  }

  override fun onCancel(p0: Any?) {
    eventSink = null
    super.onCancel(p0)
  }

}