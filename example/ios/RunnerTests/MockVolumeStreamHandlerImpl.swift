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

    // MARK: - Captured state
    public private(set) var startCallCount: Int = 0
    public private(set) var stopCallCount: Int = 0
    public private(set) var sentVolumes: [Float] = []

    /// Optional closures to observe calls in tests.
    public var onStart: (() -> Void)?
    public var onStop: (() -> Void)?
    public var onSend: ((Float) -> Void)?

//    // MARK: - Lifecycle
//    public init() {}

    // MARK: - VolumeChangeStreamHandling
    public func start() {
        startCallCount += 1
        onStart?()
    }

    public func stop() {
        stopCallCount += 1
        onStop?()
    }

    public func send(volume: Float) {
        sentVolumes.append(volume)
        onSend?(volume)
    }
}

//// MARK: - Convenience typealias
//// If production code refers to `VolumeChangeStreamHandlerImpl` concretely, this alias allows
//// injecting the mock without changing call sites when building for tests.
//#if DEBUG
//public typealias VolumeChangeStreamHandlerImpl = MockVolumeChangeStreamHandlerImpl
//#endif
