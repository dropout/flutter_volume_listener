import Flutter
import UIKit
import XCTest


@testable import flutter_volume_listener

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {
  
  
  func testExample() throws {
    XCTAssertEqual(2 + 2, 4)
  }

//  func testGetPlatformVersion() {
//    let plugin = FlutterVolumeListenerPlugin()
//
//    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])
//
//    let resultExpectation = expectation(description: "result block must be called.")
//    plugin.handle(call) { result in
//      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
//      resultExpectation.fulfill()
//    }
//    waitForExpectations(timeout: 1)
//  }

}
