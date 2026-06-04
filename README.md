# FlutterVolumeListener Plugin

## What?
A plugin for Flutter to read volume and listen to volume changes.

## Why?
On iOS, `AVAudioSession.outputVolume` can report an incorrect value after the app resumes if the system volume was changed while the app was backgrounded. This plugin tries to address that issue by providing a method that refreshes the volume reading reliably.

## How?
Expose a method `getVolumeOnResume` that uses a different approach to read the volume level reliably after the app resumes from the background:
- On iOS, it triggers a neutral volume change to refresh `AVAudioSession.outputVolume` before reading the volume.
- On Android, it behaves the same as `getVolume` and reads out value from `AudioManager`.

## Getting Started

### Setup

Use a **real device** rather than a simulator when trying to test or run the plugin on iPhone or iPad device.

## Usage

### Generic use case

```dart
final flutterVolumeListener = FlutterVolumeListener();
flutterVolumeListener.onVolumeChange.listen((volume) {
  print("Volume changed: $volume");
});
final currentVolume = await flutterVolumeListener.getVolume();
print("Current volume: $currentVolume");
```

### Use case to address the iOS background volume change issue:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state) {
      case AppLifecycleState.resumed:
        // App has come to the foreground
        // Use `getVolumeOnResume` to get the current volume on all
        // platforms reliably
        flutterVolumeListener.getVolumeOnResume().then((vol) {
          if (!mounted) return;
          setState(() {
            _currentVolume = vol;
          });
        });
        break;
      default:
        return;
    }
    super.didChangeAppLifecycleState(state);
}
```
