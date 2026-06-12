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
}

class DefaultAudioSessionManager : AudioSessionManager {
  
  let logger = Logger(label: "AudioSessionManager")
    
  private let audioSession: AVAudioSession
  private let volumeChangeHandler: VolumeChangeStreamHandlerImpl
  private var observation: NSKeyValueObservation? = nil
  
  init(audioSession: AVAudioSession, volumeChangeHandler: VolumeChangeStreamHandlerImpl) throws {
    self.audioSession = audioSession
    self.volumeChangeHandler = volumeChangeHandler
    try attachAVAudioSessionOutputVolumeKVO()
  }
  
  public func activate() throws {
    logger.info("Activating audio session")
    try audioSession.setActive(true, options: [])
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
  
  private func attachAVAudioSessionOutputVolumeKVO() throws {
    logger.info("Attaching KVO to AVAudioSession.outputVolume")
    try audioSession.setActive(true, options: [])

    observation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
      if let newValue = change.newValue {
        self?.volumeChangeHandler.onVolumeChange(volume: Double(newValue))
        self?.logger.info("AVAudioSession.outputVolume changed, new value: \(newValue)")
      }
    }
  }
  
  private func detachAVAudioSessionOutputVolumeKVO() {
    logger.info("Detaching KVO from AVAudioSession.outputVolume")
    observation?.invalidate()
    observation = nil
  }
  
  deinit {
    detachAVAudioSessionOutputVolumeKVO()
  }
  
}
