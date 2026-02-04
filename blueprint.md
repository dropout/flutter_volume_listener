# Specification: `flutter_volume_listener` Plugin

## 1. Project Overview
* **Name:** `flutter_volume_listener`
* **Description:** A Flutter plugin that provides a continuous, reactive stream of the system's media volume changes.
* **Platforms:** Android, iOS
* **Primary Goal:** Enable Flutter UI to react instantly to volume changes triggered by hardware buttons or system sliders.

## 2. Technical Architecture
The plugin will use a **Reactive Stream** pattern via Flutter's EventChannel to push update from native to Dart.

* Channel Name: `dev.adampalinkas.flutter_volume_listener/volume`
* Data Format: `double` (Floating point) Normalized volume between 0.0 and 1.0
* State Management: The native side must track the lastEmittedValue to differentiate between a change and a boundary-press event.

## 3. Implementation Details

### A. Dart API (`lib/`)

* Define a class `FlutterVolumeListener`
* Implement a private EventChannel
* Expose a public double gett `volume`
* Expose a public well-documented method Stream<double> get `onVolumeChanged`:

```dart
/// Returns a stream of volume levels. 
/// [emitOnBoundaries] if true, will emit a value even if the volume 
/// is already at min/max when a hardware button is pressed.
Stream<double> onVolumeChanged({bool emitOnBoundaries = false}) {
  return _eventChannel
      .receiveBroadcastStream(emitOnBoundaries)
      .map((event) => event as double);
}
```

### B. Android Implementation (`android/`)

* Primary API: AudioManager
* Use a ContentObserver registered to Settings.System.CONTENT_URI to listen for changes to the volume.

* Behavior:
    * On onListen: Register the observer and immediately emit the current volume.
    * On onCancel: Unregister the observer to prevent memory leaks.
    * Boundary Handling: The plugin must provide an interface or instruction to override onKeyDown in the host MainActivity.
        * Capture KeyEvent.KEYCODE_VOLUME_UP and KEYCODE_VOLUME_DOWN.
        * If `emitOnBoundaries` is true, call `eventSink.success()` even if the volume level remains unchanged.

### C. iOS Implementation (`ios/`)

* API: `AVAudioSession`
* Mechanism: Observe the `outputVolume` property using `NotificationCenter` (`SystemVolumeDidChange`) or KVO.
* Behavior:
    * On onListen: Start observing `AVAudioSession.sharedInstance().outputVolume`
    * On onCancel: Remove observer.
    * Requirement: Ensure AvAudioSession is active before reading values.
    * Boundary Handling: * When emitOnBoundaries is true, the SystemVolumeDidChange notification should trigger an emission regardless of whether the outputVolume delta is $0$.

## 4. Example Application (`example/`)
The example app must demostrate the following:
1. UI: A StreamBuilder that updates a Slider (read-only) or a Text widget with the current volume level.
2. Lifecycle: Demostrate that the stream starts when the page is pushed and stops when the page is popped.

## 5. Extended Requirement: Boundary Button Interception
**Goal:** The stream must emit a value even when the volume is already at $0.0$ or $1.0$ and a hardware volume button is pressed.

## 6. Definition of Done (Success Criteria)
* [] `flutter analyze` passes with zero warnings.
* [] Plugin build succesfully for Android (Min SDK 24)
* [] Plugin build succesfully for iOS (Min iOS 15)
* [] Changing volume via hardware buttons updates the Flutter UI in the example app in real-time.
* [] The value returned is always between 0.0 and 1.0.
* [] Calling onVolumeChanged(emitOnBoundaries: false) only triggers when the slider/value actually moves.
* [] Calling onVolumeChanged(emitOnBoundaries: true) triggers even when buttons are mashed at 0% or 100%.
