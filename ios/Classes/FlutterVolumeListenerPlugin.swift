import AVFoundation
import Flutter
import UIKit
import MediaPlayer

var _hostApi : FlutterVolumeListenerHostApi? = nil
var _volumeObserver: VolumeObserver? = nil
var _volumeChangeStreamHandler: VolumeChangeStreamHandlerImpl? = nil

public class FlutterVolumeListenerPlugin: NSObject, FlutterPlugin {
  
  // Entry point
  public static func register(with registrar: FlutterPluginRegistrar) {

    let messenger = registrar.messenger()
    
    // Setup method calls api
    _hostApi = FlutterVolumeListenerHostApiImpl()
    FlutterVolumeListenerHostApiSetup.setUp(binaryMessenger: messenger, api: _hostApi)
    
    // Setup volume change events
    _volumeChangeStreamHandler = VolumeChangeStreamHandlerImpl()
    VolumeChangeStreamHandler.register(with: messenger, streamHandler: _volumeChangeStreamHandler!)
    
    _volumeObserver = VolumeObserver(volumeChangeHandler: _volumeChangeStreamHandler!)
  }
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    _hostApi = nil
    _volumeObserver = nil
    _volumeChangeStreamHandler?.onCancel(withArguments: nil)
  }

}

// Implementation for Host API
class FlutterVolumeListenerHostApiImpl : NSObject, FlutterVolumeListenerHostApi {
  
  // Read volume from active AudioSession
  func getVolume(completion: @escaping (Result<Double, any Error>) -> Void) {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setActive(true, options: [])
    let volume = session.outputVolume
    completion(.success(Double(volume)))
  }
  
  // Read the volume from active AudioSession but trigger a neutral change before reading the value.
  // When resuming app from background and the volume has been changed, AudioSession.outputVolume is not
  // reflecting the changed volume value. We need to "kick in" with a volume setting so that up-to-date values can be
  // read from AudioSession.outputVolume and the app can show a valid volume value.
  func getVolumeOnResume(completion: @escaping (Result<Double, any Error>) -> Void) {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setActive(true, options: [])
    MPVolumeView.triggerChange()
    let volume = session.outputVolume
    completion(.success(Double(volume)))
  }
  
}

// Handle sending volume change events to Flutter
class VolumeChangeStreamHandlerImpl: VolumeChangeStreamHandler {
  
  var eventSink: PigeonEventSink<Double>?
  
  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Double>) {
    eventSink = sink
  }
  
  func onVolumeChange(volume: Double) {
    if let eventSink = eventSink {
      eventSink.success(volume)
    }
  }
  
  override func onCancel(withArguments arguments: Any?) {
    eventSink = nil
  }
  
}

// Creates a Key Value Observation for AudioSession.outputVolume, so that changes can be streamed to
// the Flutter EventChannel
class VolumeObserver: NSObject {
  private var observation: NSKeyValueObservation? = nil
  private let volumeChangeHandler: VolumeChangeStreamHandlerImpl
  
  init(volumeChangeHandler: VolumeChangeStreamHandlerImpl) {
    self.volumeChangeHandler = volumeChangeHandler
    super.init()
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(true, options: [])
    observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
        if let newValue = change.newValue {
            self?.volumeChangeHandler.onVolumeChange(volume: Double(newValue))
        }
    }
  }
  
  deinit {
    observation?.invalidate()
  }
}

// Helper extension to work with setting volume
// TODO: Make it more efficient so that no MPVolumeView is created on each method call
extension MPVolumeView {
  
  static func setVolume(_ volume: Float) {
    let volumeView = MPVolumeView()
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      slider?.value = volume
    }
  }
  
  static func triggerChange() {
    let volumeView = MPVolumeView()
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      let value = slider?.value ?? 0.5
      if (value >= 1.0) {
        slider?.value = 0.99
        slider?.value = 1.0
      } else if (value <= 0.0) {
        slider?.value = 0.01
        slider?.value = 0.0
      } else {
        slider?.value = value + 0.01
        slider?.value = value - 0.01
      }
      
    }
  }
  
}
