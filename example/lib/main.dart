import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_volume_listener/flutter_volume_listener.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  double _currentVolume = 0.0;
  final flutterVolumeListener = FlutterVolumeListener();
  StreamSubscription<double>? volumeChangeSub;

  @override
  void initState() {
    initPlatformState();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    volumeChangeSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    double volume = 0.0;
    try {
      // get initial volume
      volume = await flutterVolumeListener.volume;

      // listen to subsequent volume changes
      volumeChangeSub = flutterVolumeListener.onVolumeChanged.listen(handleVolumeChange);
    } catch (e) {
      print('Failed to get volume: $e');
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
          children: [
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
                child: AnimatedBackground(
                  triggerStream: flutterVolumeListener.onVolumeChanged,
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
                  ),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {

  final Stream triggerStream;
  final Widget child;

  const AnimatedBackground({
    required this.triggerStream,
    required this.child,
    super.key
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
  with SingleTickerProviderStateMixin{

  late final AnimationController animationController;
  late final Animation<Color?> colorAnimation;
  StreamSubscription? _triggerSubscription;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Durations.medium4,
    );

    colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.lightBlue.shade100,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    _triggerSubscription = widget.triggerStream.listen((_) {
      animationController.value = 0.0;
      animationController.forward();
    });

    animationController.value = 1.0;

  }

  @override
  void dispose() {
    animationController.dispose();
    _triggerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: colorAnimation,
      builder: (context, child) {
        return Container(
          color: colorAnimation.value ?? Colors.white70,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
