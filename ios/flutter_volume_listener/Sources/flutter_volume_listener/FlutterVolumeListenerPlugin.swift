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
  
  init(audioSessionManager: AudioSessionManager, volumeChangeStreamHandler: VolumeChangeStreamHandlerImpl, onDetach: OnDetachCallback? = nil) throws {
    self.audioSessionManager = audioSessionManager
    self.volumeChangeStreamHandler = volumeChangeStreamHandler
    self.onDetach = onDetach
    try audioSessionManager.activate()
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
    self.onDetach?()
    self.volumeChangeStreamHandler.onCancel(withArguments: nil)
  }
  
  // Read volume from active AudioSession
  func getVolume(completion: @escaping (Result<Double, any Error>) -> Void) {
    let volume = audioSessionManager.volume
    completion(.success(Double(volume)))
    logger.info("getVolume: \(volume)")
  }
    
  public func sceneDidBecomeActive(_ scene: UIScene) {
    do {
      try audioSessionManager.activate()
    } catch {
      logger.error("Failed to activate audio session when scene did become active: \(error)")
    }
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



