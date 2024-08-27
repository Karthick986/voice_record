import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Record',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Codec _codec = Codec.aacMP4;
  final String _mPath = 'audio_file.mp4';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  int playTime = 0;
  Timer? _timer;
  bool _showMic = true, _isRecorded = false;
  final theSource = AudioSource.microphone;

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {});
    });

    openTheRecorder().then((value) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  void record() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _mRecorder!
          .startRecorder(
        toFile: _mPath,
        codec: _codec,
        audioSource: theSource,
      )
          .then((value) {
        _showMic = false;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            playTime++;
          });
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please allow microphone access")));
    }
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        playTime = 0;
        _timer?.cancel();
        _showMic = true;
        _isRecorded = true;
      });
    });
  }

  void play() {
    assert(_mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
        fromURI: _mPath,
        whenFinished: () {
          setState(() {
            playTime = 0;
            _timer?.cancel();
          });
        })
        .then((value) {
          setState(() {
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                playTime++;
              });
            });
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Stack(
        children: [
          Center(
            child: AvatarGlow(
              animate: !_showMic,
              child: IconButton(
                icon: Icon(_isRecorded ?
                    Icons.play_arrow:
                  _showMic ? Icons.mic : Icons.stop,
                  color: Colors.white,
                  size: 100,
                ),
                onPressed: () {
                  if (_isRecorded) {
                    play();
                  } else if (_showMic) {
                    record();
                  } else {
                    stopRecorder();
                  }
                },
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 100,
                ),
                Text(
                  _printDuration(Duration(seconds: playTime)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    "Interview with Dr. Yang",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "175 5th Ave, New York, NY, 10010",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_isRecorded) {
                    setState(() {
                      _isRecorded = false;
                    });
                  }
                },
                child: Column(
                  children: [
                    Text(
                      _isRecorded ? "Tap to record another" : "Tap to Bookmark",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      "👉 Swipe right to pause",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
