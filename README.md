# FlutterVolumeListener Plugin

## What?
A plugin for Flutter to reliably read volume and listen to volume changes.

## Why?
On **iOS**, `AVAudioSession.outputVolume` can report an incorrect values after the app resumes if the system volume was changed while the app was backgrounded.

### Problems on iOS
- After a volume change while backgrounding `AVAudioSession.outputVolume` reports a stale cached value not the updated one
- KVO on `AVAudioSession.outputVolume` does not report change, since value is stuck
- Need to initiate a volume change while the app is in the foreground to receive volume changes while backgrounding
- Does not happen when connected to debugger
- Does not happen when the app kept alive with backgrounding capability


## How?
Uses `MPVolumeView` slider value (which receives correct system volume changes) to read out volume data to make sure its always up to date. On Android, no additional behaviour.

### Functionality
- Exposes a `.volume` getter on the plugin interface to read out volume values. Reads out updated value even after change while backgrounding.
- Exposes a stream `.onVolumeChanged` to listen to volume changes. If a value has been changed while backgrounding the new updated value will be received through the stream when the app becomes active.

### Solution on iOS
- Add an `MPVolumeView` to receive volume changes through internal behaviour (rounding to 0.05 steps, just like outputVolume readouts)
- Read out `MPVolumeView` slider value to infer the current volume value
- If slider value cannot be read, fall back to `AVAudioSession.outputVolume`

## Getting Started

### Setup

Use a **real device** rather than a simulator when trying to test or run your application.

## Usage

### Generic use case

```dart

// Create an instance of the plugin
final flutterVolumeListener = FlutterVolumeListener();

// Read out volume values
final currentVolume = await flutterVolumeListener.volume;
print("Current volume: $currentVolume");

// Use the stream to listen to changes
final volumeChangeSub = flutterVolumeListener.onVolumeChanged.listen((volume) {
  print("Volume changed: $volume");
});

// Cleanup: cancel the subscription
volumeChangeSub.cancel();

```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
