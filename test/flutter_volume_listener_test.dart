// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_volume_listener/flutter_volume_listener.dart';
// import 'package:flutter_volume_listener/flutter_volume_listener_platform_interface.dart';
// import 'package:flutter_volume_listener/flutter_volume_listener_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockFlutterVolumeListenerPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterVolumeListenerPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
//
//   @override
//   Future<double> getVolume() => Future.value(0.5);
//
//   @override
//   Stream<double> getOnVolumeChanged() => Stream<double>.fromIterable([0.5, 0.7, 0.3]);
// }
//
// void main() {
//   final FlutterVolumeListenerPlatform initialPlatform = FlutterVolumeListenerPlatform.instance;
//
//   test('$MethodChannelFlutterVolumeListener is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterVolumeListener>());
//   });
//
//   // test('getPlatformVersion', () async {
//   //   FlutterVolumeListener flutterVolumeListenerPlugin = FlutterVolumeListener();
//   //   MockFlutterVolumeListenerPlatform fakePlatform = MockFlutterVolumeListenerPlatform();
//   //   FlutterVolumeListenerPlatform.instance = fakePlatform;
//   //
//   //   expect(await flutterVolumeListenerPlugin.getPlatformVersion(), '42');
//   // });
// }
