import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/flutter_volume_listener.g.dart',
    kotlinOut:
      'android/src/main/kotlin/dev/adampalinkas/flutter_volume_listener/FlutterVolumeListenerPlugin.g.kt',
    swiftOut: 'ios/flutter_volume_listener/Sources/flutter_volume_listener/FlutterVolumeListenerPlugin.g.swift',
    dartPackageName: 'flutter_volume_listener',
  )
)

@EventChannelApi()
abstract class FlutterVolumeListenerEventApi {
  double volumeChange();
}

@HostApi()
abstract class FlutterVolumeListenerHostApi {
  @async
  double getVolume();
}
