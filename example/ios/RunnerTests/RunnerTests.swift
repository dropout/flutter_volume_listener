import Flutter
import UIKit
import XCTest
import AVFoundation

@testable import flutter_volume_listener

class FlutterVolumeListenerPluginTests: XCTestCase {
  
  
//  override func setUp() {
//    super.setUp()
//    mockAudioSessionManager = MockAudioSessionManager()
//  }
//  
//  override func tearDown() {
//    mockAudioSessionManager = nil
//    super.tearDown()
//  }
  
  func testPluginInitializationActivatesAudioSessionManager() throws {
    // Given
    let mockAudioSessionManager = MockAudioSessionManager()
    let mockVolumeChangeStreamHandler = MockVolumeChangeStreamHandlerImpl()

    // When: instantiate plugin with the mock audio session manager
    // Adjust the initializer to match your plugin's API
    let plugin = try FlutterVolumeListenerPlugin(
      audioSessionManager: mockAudioSessionManager,
      volumeChangeStreamHandler: mockVolumeChangeStreamHandler,
    )
    _ = plugin // silence unused warning if needed

    // Then
    XCTAssertEqual(mockAudioSessionManager.activateCallCount, 1, "AudioSessionManager.activate() should be called during plugin initialization")
  }
  
  func testGetVolumeCallsAudioSessionManagerVolumeGetter() throws {
    // Given
    let mockAudioSessionManager = MockAudioSessionManager()
    let mockVolumeChangeStreamHandler = MockVolumeChangeStreamHandlerImpl()

    // Ensure initial state
    XCTAssertEqual(mockAudioSessionManager.getVolumeCallCount, 0, "Precondition: volume getter should not have been called yet")

    // When: instantiate plugin and call getVolume
    let plugin = try FlutterVolumeListenerPlugin(
      audioSessionManager: mockAudioSessionManager,
      volumeChangeStreamHandler: mockVolumeChangeStreamHandler
    )
    
    // Provide completion closure and verify it's used
    let completionCalled = XCTestExpectation(description: "getVolume completion called")
    var completionVolume: Double?
    plugin.getVolume { result in
      switch result {
      case .success(let volume):
        completionVolume = volume
      case .failure(let error):
        XCTFail("getVolume failed with error: \(error)")
      }
      completionCalled.fulfill()
    }
    // Wait for completion to be called
    wait(for: [completionCalled], timeout: 1.0)

    // Then: volume getter should have been accessed exactly once
    XCTAssertEqual(mockAudioSessionManager.getVolumeCallCount, 1, "AudioSessionManager.volume getter should be called when getVolume() is invoked")
    // Verify the completion received a volume value
    XCTAssertNotNil(completionVolume, "Completion should be called with a volume value")
  }
  
}
