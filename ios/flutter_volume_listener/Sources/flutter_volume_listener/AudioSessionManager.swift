//
//  AudioSessionManager.swift
//  flutter_volume_listener
//
//  Created by Adam Palinkas on 2026. 06. 11..
//

import MediaPlayer
import Logging

protocol AudioSessionManager {
  var volume: Float { get }
  func activate() throws
  func observeVolumeChange(onChange: @escaping (Double) -> Void) throws -> NSKeyValueObservation?
}

class DefaultAudioSessionManager : AudioSessionManager {
  
  let logger = Logger(label: "AudioSessionManager")
  
  // An AVAudioSession instance to work on
  private let audioSession: AVAudioSession
  
  init(audioSession: AVAudioSession, volumeChangeHandler: VolumeChangeStreamHandlerImpl) throws {
    self.audioSession = audioSession
    try activate()
  }
  
  public func activate() throws {
    logger.info("Activating audio session")
    try audioSession.setActive(true, options: [])
    // Force .playback for now to make outputVolume read consistent after backgrounding
    try audioSession.setCategory(.playback, options: [])
  }
    
  var volume: Float {
    get {
      if (audioSession.category != .playback) {
        logger.warning("AVAudioSession.category is not .playback, might return stale value after backgrounding")
      }
      return audioSession.outputVolume
    }
  }
  
  func observeVolumeChange(onChange: @escaping (Double) -> Void) throws -> NSKeyValueObservation? {
    // 1. Create and return the observation object
    try activate()
    return audioSession.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
      guard let newValue = change.newValue else { return }
      
      // 2. Call the passed-in callback with the new volume
      onChange(Double(newValue))
      
      // 3. Keep your logging if needed
      self?.logger.info("AVAudioSession.outputVolume changed, new value: \(newValue)")
    }
  }
  
}
