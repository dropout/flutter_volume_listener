import AVFoundation
import MediaPlayer
import Flutter
import UIKit
import Logging

typealias OnDetachCallback = () -> Void

// Plugin
public class FlutterVolumeListenerPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate, FlutterVolumeListenerHostApi {
  
  private let logger = Logger(label: "FlutterVolumeListenerPlugin")
  
  private let audioSessionManager: AudioSessionManager
  private let volumeChangeStreamHandler: VolumeChangeStreamHandlerImpl
  private let onDetach: OnDetachCallback?
  
  private var observation: NSKeyValueObservation?
  
  private var mpvView: MPVolumeView?
  
  
  init(audioSessionManager: AudioSessionManager, volumeChangeStreamHandler: VolumeChangeStreamHandlerImpl, onDetach: OnDetachCallback? = nil) throws {
    self.audioSessionManager = audioSessionManager
    self.volumeChangeStreamHandler = volumeChangeStreamHandler
    self.onDetach = onDetach
        
    observation = try audioSessionManager.observeVolumeChange(onChange: volumeChangeStreamHandler.onVolumeChange)
  }
  
  // Entry point
  public static func register(with registrar: FlutterPluginRegistrar) {
    let logger = Logger(label: "FlutterVolumeListenerPlugin.register")
    do {
      let messenger = registrar.messenger()
      
      // Attach stream handler to the volume observer
      let streamHandler = VolumeChangeStreamHandlerImpl()
      let audioSessionManager = try DefaultAudioSessionManager(audioSession: AVAudioSession.sharedInstance(), volumeChangeHandler: streamHandler)
      
      // Register the stream handler instance
      VolumeChangeStreamHandler.register(with: messenger, streamHandler: streamHandler)
      
      // Setup the Pigeon host api
      let plugin = try FlutterVolumeListenerPlugin(
        audioSessionManager: audioSessionManager,
        volumeChangeStreamHandler: streamHandler,
        onDetach: {
          // Here we eliminate the registered instance of the plugin (which implements the hostapi) that can gracefully release resources
          FlutterVolumeListenerHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
          logger.info("Reference for the plugin has been nulled")
        }
      )
      
      // Register this instance to receive lifecycle callbacks
      registrar.addSceneDelegate(plugin)
      
      // Setup plugin instance in the registrar that will hold a strong reference to it
      FlutterVolumeListenerHostApiSetup.setUp(binaryMessenger: messenger, api: plugin)
    } catch {
      logger.error("Unable to register plugin: \(error)")
    }
  }
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    logger.info("Detached from engine")
    // Will make use of binarymessenger to null out the plugins strong reference
    // and we don't have to keep a messenger reference inside the plugin
    // This makes testing easier
    self.onDetach?()
    
    // Cancel the outputVolume KVO
    self.observation?.invalidate()
    self.observation = nil
    
    // Cancel the volume change stream
    self.volumeChangeStreamHandler.onCancel(withArguments: nil)
    
    // Remove the
    tearDownVolumeView()
  }
  
  // Read volume from active AudioSession
  func getVolume(completion: @escaping (Result<Double, any Error>) -> Void) {
    let volume = readVolume()
    completion(.success(Double(volume)))
    logger.info("getVolume: \(volume)")
  }
    
  public func sceneDidBecomeActive(_ scene: UIScene) {
    logger.info("Scene did become active")
    do {
      try audioSessionManager.activate()
      // Maybe not added on app launch, try to
      // do that now
      if (mpvView == nil) {
        setupVolumeView()
      }
      let sliderVolume = readSliderValue()
      
      let a = roundToNearestFiveHundredth(audioSessionManager.volume)
      
      // If we cannot get a slider value fall back to .outputVolume,
      let b = roundToNearestFiveHundredth(sliderVolume ?? audioSessionManager.volume)
      
      // System volume slider and AVAudioSession.outputVolume differs,
      // since .outputVolume sometimes reports stale value after backgrounding
      // we take the slider value and propagate a change
      logger.info("Compared volume: \(a) with slider: \(b)")
      logger.info("Slider value was available: \(sliderVolume != nil)")
      if (a != b) {
        volumeChangeStreamHandler.onVolumeChange(volume: Double(b))
        logger.info("Volume change propagated: \(b)")
      } else {
        logger.info("No need to propagate volume change")
      }
//      tearDownVolumeView()
    } catch {
      logger.error("Failed to activate audio session when scene did become active: \(error)")
    }
  }
      
  /// Rounds a floating-point value to the nearest multiple of 0.05, clamped to [0.0, 1.0].
  /// - Parameter value: The input value (e.g., a volume between 0.0 and 1.0).
  /// - Returns: The value rounded to the nearest 0.05 (two decimals), e.g. 0.00, 0.05, 0.10, 1.15 -> 1.15.
  private func roundToNearestFiveHundredth(_ value: Float) -> Float {
    // Clamp to a reasonable range for volume-like values
    let clamped = max(0.0, min(1.0, value))
    // 0.05 = 1/20, so multiply by 20, round to nearest integer, then divide back
    let stepped = (clamped * 20.0).rounded() / 20.0
    // Ensure two-decimal precision by formatting then parsing if needed
    // but keep it as Float for performance/usage.
    return Float(stepped)
  }
  
  /// Take the slider value prioritized and fallback to .outputVolume since
  /// it can contain stale values after backgrounding
  private func readVolume() -> Float {
    let vol = audioSessionManager.volume
    let sliderVolume = readSliderValue()
    if (sliderVolume != nil) {
      return roundToNearestFiveHundredth(sliderVolume ?? vol)
    } else {
      return vol
    }
  }
  
  /// Sets up a media player volume view to read out system ui slider
  /// values
  private func setupVolumeView() {
        
    guard self.mpvView == nil else {
      return
    }
    
    let view = MPVolumeView(frame: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
    view.showsVolumeSlider = true
    view.alpha = 0.000001
    view.isHidden = true
    
    // Attempt to add to the key window on the main actor
    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
       let keyWindow = windowScene.keyWindow {
        keyWindow.addSubview(view)
        self.mpvView = view
        logger.info("MPVolumeView added to keyWindow")
        return
    } else {
      logger.info("Failed to add MPVolumeView to keyWindow")
    }
  }
  
  private func readSliderValue() -> Float? {
    let slider = mpvView?.subviews.first(where: { $0 is UISlider }) as? UISlider
    return slider?.value
  }
  
  /// Destroy the MPVolumeView
  private func tearDownVolumeView() {
    mpvView?.removeFromSuperview()
    mpvView = nil
    logger.info("MPVolumeView removed from superview")
  }
  
  deinit {
    // Make sure its removed
    tearDownVolumeView()
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
