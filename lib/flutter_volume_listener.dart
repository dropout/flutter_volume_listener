import 'flutter_volume_listener.g.dart';

class FlutterVolumeListener {

  static final Stream<double> _volChange = volumeChange();

  final _api = FlutterVolumeListenerHostApi();

  // Method to get current volume
  Future<double> get volume => _api.getVolume();

  // Event channel for volume changes
  Stream<double> get onVolumeChanged => _volChange;

}
