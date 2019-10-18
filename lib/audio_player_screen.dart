import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'theme_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  bool isPlaying = false;
  static const platform = const MethodChannel("flutter.native.audio.bridge");
  String responseFromNative;
  String greetings;
  bool isPlayingAudio = false;
  int difference;
  String url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  Timer playStateTimer;
  Timer seekBarTimer;
  double progress = 0.0;
  Timer seekBarMaxDurationTimer;
  double maxProgress = 0.0;
  Timer bufferingTimer;
  bool isBuffering = false;
  Timer maxVolumeTimer;
  Timer volumeTimer;
  double volumeProgress = 0.0;
  double maxVolumeProgress = 0.0;
  int speedIndex = 0;
  String currentSpeed = "1x";

  //temp Timer Variables
  bool tempIsPlayingAudio = false;
  double tempMaxProgress = 0.0;
  double tempMaxVolumeProgress = 0.0;
  bool shouldStartSeekTimer = false;
  String audioDuration = "";
  double seconds, minuits, hour;

  @override
  void initState() {
    startTimer();
    super.initState();
  }

  startTimer() {
    playStateTimer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      tempIsPlayingAudio = await getPlayingState();

      if (isPlayingAudio != tempIsPlayingAudio) {
        setState(() {
          isPlayingAudio = tempIsPlayingAudio;
        });
      }

      tempMaxProgress = await getSeekBarMaxProgress();

      if (maxProgress != tempMaxProgress) {
        setState(() {
          maxProgress = tempMaxProgress;
          print("maxProgress==>$maxProgress");
        });
      }

      tempMaxVolumeProgress = await getMaxVolume();
      if (maxVolumeProgress != tempMaxVolumeProgress) {
        setState(() {
          maxVolumeProgress = tempMaxVolumeProgress;
        });
      }
    });
  }

  @override
  void dispose() {
    playStateTimer?.cancel();
    bufferingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 270,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: WaveWidget(
                    config: CustomConfig(
                      gradients: [
                        [Colors.pinkAccent, Colors.pink.shade400],
                        [orange, Colors.pinkAccent.shade100],
                      ],
                      durations: [19440, 10800],
                      heightPercentages: [0.10, 0.20],
                      blur: MaskFilter.blur(BlurStyle.solid, 10),
                      gradientBegin: Alignment.bottomLeft,
                      gradientEnd: Alignment.topRight,
                    ),
                    waveAmplitude: 0,
                    size: Size(
                      double.infinity,
                      double.infinity,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                top: 0.0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    alignment: Alignment.center,
                    height: 150.0,
                    width: 150.0,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: pink.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 15,
                          )
                        ],
                        border: Border.all(color: Colors.pink, width: 2.5),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: AssetImage("images/dummy_album_cover.jpg"),
                        )),
                  ),
                ),
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 20.0),
            alignment: Alignment.center,
            child: Text(
              "Song Name Goes Here",
              style: TextStyle(
                  fontFamily: "Regular",
                  color: Colors.blueGrey,
                  fontSize: 20.0),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 30.0),
            child: Slider(
              activeColor: Colors.pink,
              inactiveColor: Colors.blueGrey,
              onChanged: (value) {
                setState(() {
                  progress = value;
                  seekTo(progress);
                  // bufferngTimerStart();
                });
              },
              onChangeStart: (value) {
                shouldStartSeekTimer = false;
                //  seekBarTimer?.cancel();
              },
              onChangeEnd: (value) {
                shouldStartSeekTimer = true;
                // seekBarTimerStart();
              },
              value: progress,
              min: 0.0,
              max: maxProgress,
            ),
          ),
          _buildDuration(),
          SizedBox(
            height: 5.0,
          ),
          _buildPausePlayAction(),
          SizedBox(
            height: 5.0,
          ),
          _buildVolumeAction(),
          SizedBox(
            height: 5.0,
          ),
          GestureDetector(
            onTap: () {
              speedIndex++;
              if (speedIndex == 4) {
                speedIndex = 0;
              }
              switch (speedIndex) {
                case 0:
                  {
                    setState(() {
                      currentSpeed = "1x";
                      setSpeedXPlayer("1X").then((value) {});
                    });
                  }
                  break;
                case 1:
                  {
                    setState(() {
                      currentSpeed = "0.5x";
                      setSpeedXPlayer("0.5x").then((value) {});
                    });
                  }
                  break;
                case 2:
                  {
                    setState(() {
                      currentSpeed = "0.75x";
                      setSpeedXPlayer("0.75x").then((value) {});
                    });
                  }
                  break;
                case 3:
                  {
                    setState(() {
                      currentSpeed = "2x";
                      setSpeedXPlayer("2x").then((value) {});
                    });
                  }
                  break;
              }

              if (speedIndex == 0) {
                currentSpeed = "1x";
                setSpeedXPlayer("1x").then((value) {});
              }
            },
            child: Container(
              width: 50.0,
              height: 50.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink.withOpacity(0.5),
              ),
              child: Text(
                currentSpeed,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontFamily: "BoldFont"),
              ),
              padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildDuration() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            child: Text(
              convertedDuration(progress),
              style: TextStyle(
                  fontFamily: "Regular",
                  color: Colors.blueGrey,
                  fontSize: 12.0),
            ),
            decoration: BoxDecoration(
                shape: BoxShape.rectangle, border: Border.all(color: white)),
          ),
          Container(
            child: Text(
              convertedDuration(maxProgress),
              style: TextStyle(
                  fontFamily: "Regular",
                  color: Colors.blueGrey,
                  fontSize: 12.0),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPausePlayAction() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 50.0,
            width: 50.0,
            child: IconButton(
              onPressed: () {
                print("in__buildPlayPause");
                //click on backward
                setState(() {
                  if (progress > 10000) {
                    progress = progress - 10000;
                  } else {
                    progress = 0;
                  }
                });
                seekTo(progress);
              },
              icon: Icon(
                Icons.skip_previous,
                color: Colors.blueGrey,
                size: 30.0,
              ),
            ),
          ),
          Stack(
            children: <Widget>[
              Positioned(
                top: 2.0,
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Align(
                  alignment: Alignment.center,
                  child: Visibility(
                    visible: isBuffering,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          child: SpinKitDualRing(
                            lineWidth: 1.0,
                            color: pink,
                            size: 50.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 100.0,
                width: 100.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                  child: Container(
                    height: 65.0,
                    width: 65.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(),
                    child: IconButton(
                      onPressed: () {
                        print("in__buildPlayPause");
                        setState(() {
                          setPlayPauseState();
                        });
                        bufferngTimerStart();
                      },
                      icon: Icon(
                        isPlayingAudio ? Icons.pause : Icons.play_arrow,
                        color: Colors.blueGrey,
                        size: 35.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 50.0,
            width: 50.0,
            child: IconButton(
              onPressed: () {
                print("in__buildPlayPause");
                //click on backward
                setState(() {
                  progress = progress + 10000;
                });
                seekTo(progress);
              },
              icon: Icon(
                Icons.skip_next,
                color: Colors.blueGrey,
                size: 30.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeAction() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              setVolume(0);
            },
            icon: Icon(
              Icons.volume_mute,
              color: Colors.blueGrey,
              size: 25.0,
            ),
          ),
          Flexible(
              child: Slider(
            onChanged: (value) {
              setState(() {
                volumeProgress = value;
              });
              setVolume(volumeProgress);
            },
            onChangeStart: (value) {
              volumeTimer.cancel();
            },
            onChangeEnd: (value) {
              setState(() {
                volumeProgress = value;
              });
              startVolumeTimer();
            },
            value: volumeProgress,
            min: 0.0,
            max: maxVolumeProgress,
            activeColor: Colors.pink,
            inactiveColor: Colors.blueGrey,
          )),
          IconButton(
            onPressed: () {
              setVolume(maxVolumeProgress);
            },
            icon: Icon(
              Icons.volume_up,
              color: Colors.blueGrey,
              size: 25.0,
            ),
          ),
        ],
      ),
    );
  }

  String convertedDuration(double miliseconds) {
    seconds = (miliseconds / 1000) % 60;
    minuits = (miliseconds / (1000 * 60)) % 60;
    hour = miliseconds / (1000 * 60 * 60);

    int hours = hour.toInt();
    int min = minuits.toInt();
    int sec = seconds.toInt();

    audioDuration =
        hours.toString() + ":" + min.toString() + ":" + sec.toString();

    return audioDuration;
  }

  //for audio seekbar progress
  Future<double> getSeekBarProgress() async {
    double response;
    try {
      var result = await platform.invokeMethod("setSeekBarProgress");
      response = result;
      print("progress:::$response");
    } on PlatformException catch (e) {
      print("error progress:::${e.message.toString()}");
    }
    if (context != null) {
      setState(() {
        progress = response;
      });
    }
    return progress;
  }

  //check if audio is playing/pause
  Future<bool> getPlayingState() async {
    bool response;
    try {
      bool result = await platform.invokeMethod("setPlayingState");
      response = result;
      print("playingState:::$response");
    } on PlatformException catch (e) {
      print("error playingState:::${e.message.toString()}");
    }

    return response;
  }

  //Get max value(duration) of audio
  Future<double> getSeekBarMaxProgress() async {
    double response;
    try {
      var result = await platform.invokeMethod("setSeekBarMaxProgress");
      response = result;
      print("Maxprogress:::$response");
    } on PlatformException catch (e) {
      print("error Maxprogress:::${e.message.toString()}");
    }

    if (response > 0) {
      seekBarMaxDurationTimer?.cancel();
      seekBarTimerStart();
    }
    return response;
  }

  //gives the max volume value
  Future<double> getMaxVolume() async {
    double response;
    try {
      var result = await platform.invokeMethod("getMaxVolume");
      response = result;
      print("getMaxVolume:::$response");
    } on PlatformException catch (e) {
      print("error getMaxVolume:::${e.message.toString()}");
    }

    if (response > 0) {
      //new maxVolumeTimer.cancel();

      startVolumeTimer();
    }
    return response;
  }

  //change state of player on click of a button
  setPlayPauseState() {
    if (isPlayingAudio) {
      pausePlayer().then((value) {});
    } else {
      playPlayer(url, "Description", "Title").then((value) {});
    }
  }

  //get value of level of volume
  Future<double> getVolumeProgress() async {
    double response;
    try {
      var result = await platform.invokeMethod(
        "getVolumeProgress",
      );
      response = result;
      print("getVolumeProgress:::$response");
    } on PlatformException catch (e) {
      print("error getVolumeProgress:::${e.message.toString()}");
    }
    if (volumeProgress != response) {
      if (context != null) {
        setState(() {
          volumeProgress = response;
        });
      }
    }

    return volumeProgress;
  }

  void setVolume(double volume) async {
    String response = "";
    try {
      String result =
          await platform.invokeMethod("setVolume", {"volume": volume});
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  //get the state of volume every second
  startVolumeTimer() {
    volumeTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      getVolumeProgress();
    });
  }

  //get the state of seekbar every second
  seekBarTimerStart() {
    seekBarTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      getSeekBarProgress();
    });
  }

  //get the state of loader every second
  bufferngTimerStart() {
    bufferingTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      getBufferingState();
    });
  }

  //start the player
  playPlayer(String url, String description, String title) async {
    String response = "";
    try {
      String result = await platform.invokeMethod(
          "startPlayer", {"url": url, "title": title, "desc": description});
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  //pause the player
  pausePlayer() async {
    String response = "";
    try {
      String result = await platform.invokeMethod("pausePlayer");
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  //seek to particular progress
  void seekTo(double second) async {
    String response = "";
    try {
      String result =
          await platform.invokeMethod("seekTo", {"milisecond": second});
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  //set new speed for player
  setSpeedXPlayer(String speedValue) async {
    String response = "";
    try {
      String result = await platform
          .invokeMethod("speedXPlayer", {"speedValue": speedValue});
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  //skip to 10 back in audio
  backwardPlayer() async {
    String response = "";
    try {
      String result = await platform.invokeMethod("backwardPlayer");
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  skipAudio() async {
    String response = "";
    try {
      String result = await platform.invokeMethod("skipAudio");
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to invoke native method ${e.message.toString()}";
    }
  }

  Future<bool> getBufferingState() async {
    bool response = false;
    try {
      bool result = await platform.invokeMethod("getBuffering");
      response = result;
      print("boolean value of res==>${response.toString()}");
    } on Exception catch (e) {
      print("Failed to invoke native method ${e.toString()}");
    }

    if (isBuffering != response) {
      print("inside SetState");
      setState(() {
        isBuffering = response;
        print("buffering value ==>${isBuffering.toString()}");
      });
    }
    return isBuffering;
  }
}
