//
//  MockVolumeStreamHandlerImpl.swift
//  Runner
//
//  Created by Adam Palinkas on 2026. 06. 12..
//

import Foundation
import AVFoundation
@testable import flutter_volume_listener

/// A mock implementation that can be injected anywhere a VolumeChangeStreamHandlerImpl is required.
/// It records calls for assertions and allows emitting synthetic volume events.
public final class MockVolumeChangeStreamHandlerImpl: VolumeChangeStreamHandlerImpl {
    
  private(set) var onVolumeChangeCallCount: Int = 0
  private(set) var receivedVolumes: [Double] = []
      
  public override func onVolumeChange(volume: Double) {
    onVolumeChangeCallCount += 1
    receivedVolumes.append(volume)
  }

}
