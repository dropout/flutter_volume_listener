import Foundation

@testable import flutter_volume_listener

/// A simple mock for `AudioSessionManager` to be used in tests.
/// - Configure `stubbedVolume` to control what `volume` returns.
/// - Set `activateShouldThrow` to simulate failures from `activate()`.
final class MockAudioSessionManager: AudioSessionManager {
  
  // MARK: - Stubs
  var stubbedVolume: Float = 0.5
  var activateShouldThrow: Error? = nil

  // MARK: - Call tracking
  private(set) var activateCallCount: Int = 0
  private(set) var getVolumeCallCount: Int = 0
  private(set) var observeVolumeChangeCallCount: Int = 0

  // MARK: - AudioSessionManager
  var volume: Float {
    getVolumeCallCount += 1
    return stubbedVolume
  }

  func activate() throws {
    activateCallCount += 1
    if let error = activateShouldThrow {
      throw error
    }
  }
  
  func observeVolumeChange(onChange: @escaping (Double) -> Void) throws -> NSKeyValueObservation? {
    observeVolumeChangeCallCount += 1
    onChange(0.75)
    return nil
  }
  
}

/// A lightweight error type for simulating failures in tests.
enum MockAudioSessionError: Error, Equatable {
    case activateFailed
}
