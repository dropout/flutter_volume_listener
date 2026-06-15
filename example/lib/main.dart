import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_volume_listener/flutter_volume_listener.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // Create an instance of FlutterVolumeListener
  final flutterVolumeListener = FlutterVolumeListener();

  // Current volume level
  double _currentVolume = 0.0;
  
  // Subscription to volume change events
  StreamSubscription<double>? volumeChangeSub;

  bool get isSubscribed => volumeChangeSub != null && !volumeChangeSub!.isPaused;

  @override
  void initState() {
    initPlatformState();
    super.initState();
  }

  @override
  void dispose() {
    volumeChangeSub?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    double volume = 0.0;
    try {
      // get initial volume
      volume = await flutterVolumeListener.volume;

      // listen to subsequent volume changes
      volumeChangeSub = flutterVolumeListener.onVolumeChanged.listen(handleVolumeChange);
    } catch (e) {
      debugPrint('Failed to get volume: $e');
    }

    // triggen an initial change
    handleVolumeChange(volume);
  }

  void handleVolumeChange(double vol) {
    if (!mounted) return;
    setState(() {
      _currentVolume = vol;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Volume Listener Example'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Volume info display
            SizedBox(
              width: double.infinity,
              height: 200,
              child: GestureDetector(
                onTap: () async {
                  final vol = await flutterVolumeListener.volume;
                  setState(() {
                    _currentVolume = vol;
                  });
                },
                child: TweenAnimationBuilder<Color?>(
                  key: ValueKey(_currentVolume),
                  tween: ColorTween(
                    begin: Colors.blueAccent.shade100,
                    end: Colors.lightBlue.shade100,
                  ),
                  duration: Durations.short4,
                  builder: (BuildContext context, Color? color, Widget? child) {
                    return Container(
                      color: color,
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Current Volume:"),
                      Text(
                        '${(_currentVolume * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ),

            // Volume controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text("Listen to volume changes"),
                  Switch(value: isSubscribed, onChanged: (value) {
                    if (value) {
                      volumeChangeSub?.resume();
                    } else {
                      volumeChangeSub?.pause();
                    }
                    setState(() {});
                  }),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton(
                onPressed: () async {
                  final vol = await flutterVolumeListener.volume;
                  setState(() {
                    _currentVolume = vol;
                  });
                },
                child: const Text("Refresh Volume")
              ),
            ),
            

          ],
        ),
      ),
    );
  }
}
