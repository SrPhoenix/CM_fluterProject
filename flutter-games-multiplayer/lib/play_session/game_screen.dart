// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/player_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:multiplayer/style/confetti.dart';
import 'package:multiplayer/win_game/score.dart';
import 'package:provider/provider.dart';

import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreen();
}

class _GameScreen extends State<GameScreen> {
    late PlayerController controller;
    ChartSeriesController? _chartSeriesController;
    late List<Player> players;
    late DateTime _startOfPlay;
    static const _celebrationDuration = Duration(milliseconds: 2000);
    bool lost =false;
    static const _preCelebrationDuration = Duration(milliseconds: 500);
    bool _duringCelebration = false;
    int upperBounder = 98;
    int lowerBounder = 82;
    late StreamSubscription dataListener;

    Map<String, List<double>> heartRateData = {};

    double currentHeartRate = 0.0;

      @override
  void initState() {
    super.initState();
    controller = context.read<PlayerController>();
    _startOfPlay = DateTime.now();
    createdDataListener();
    for (Player user in controller.connectedUsers){
      heartRateData[user.displayName] = [];
    }
  }

    Future<void> _playerWon(Score score) async {

      // Let the player see the game just after winning for a bit.
      await Future<void>.delayed(_preCelebrationDuration);
      if (!mounted) return;

      setState(() {
        _duringCelebration = true;
      });

      final audioController = context.read<AudioController>();
      audioController.playSfx(SfxType.congrats);

      /// Give the player some time to see the celebration animation.
      await Future<void>.delayed(_celebrationDuration);
      if (!mounted) return;

      GoRouter.of(context).go('/play/won', extra: {'score': score});
    }

    void createdDataListener() {
      dataListener = controller.uiStream.listen((data) {
        var jsonData = jsonDecode(data);
        if (jsonData["Command"] == "HEART_RATE") {
          var username = jsonData["Username"] as String;
          var heartRate = double.parse(jsonData["HeartRate"] as String);
          heartRateData[username]!.add(heartRate);
          setState(() {
            currentHeartRate = heartRate;
          });
          if (heartRateData[username]!.length == 20) {
            heartRateData[username]!.removeAt(0);
            _chartSeriesController?.updateDataSource(
                addedDataIndex: heartRateData.length - 1, removedDataIndex: 0);
          }
        }else if(jsonData["Command"] == "END_GAME"){
          Duration duration = Duration(seconds: int.parse(jsonData["Duration"] as String));
          _playerWon(Score(jsonData["Username"] as String,duration));
        }
    });
  }

    @override
    void dispose() async {
      super.dispose();
      await dataListener.cancel();
    }
    
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerController = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();
    const gap = SizedBox(height: 10);
    return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Serious Game!',
                        style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                      ),
                      IconButton(
                        icon: Icon(Icons.door_front_door, color: Colors.red,),
                        onPressed: () {
                          playerController.leaveMatch();
                          GoRouter.of(context).go('/play/joinRoom');
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: const NumericAxis(
                      isVisible: false,
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                      interval: 10,
                      minimum: controller.getStartHeartRateOfUsername(controller.username) - 10,
                      maximum: controller.getStartHeartRateOfUsername(controller.username) + 10,
                      plotBands: [
                        PlotBand(
                          start: controller.getStartHeartRateOfUsername(controller.username) - 10,
                          end: controller.getStartHeartRateOfUsername(controller.username) - 10,
                          borderColor: Colors.red,
                          borderWidth: 4,
                        ),
                        PlotBand(
                          start: controller.getStartHeartRateOfUsername(controller.username) + 10,
                          end: controller.getStartHeartRateOfUsername(controller.username) + 10,
                          borderColor: Colors.red,
                          borderWidth: 4,
                        ),
                      ],
                    ),
                    series: <LineSeries<double, int>>[
                      LineSeries<double, int>(
                        onRendererCreated: (ChartSeriesController controller) {
                          _chartSeriesController = controller;
                        },
                        dataSource: heartRateData[controller.username],
                        xValueMapper: (_, index) => index,
                        yValueMapper: (heartRate, _) => heartRate,
                      ),
                    ],
                  ),
                      Text(currentHeartRate != 0
                      ? currentHeartRate.toString()
                                  : "--",
                        style: const TextStyle(
                            fontSize: 60,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway'),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Send'),
                  // SizedBox.expand(
                  //   child: Visibility(
                  //     visible: _duringCelebration,
                  //     child: IgnorePointer(
                  //       child: Confetti(
                  //         isStopped: !_duringCelebration,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 16),
                  const Text('Log'),
                ],
              ),
            ),
          ),
        ),
      );
  
  
  }
}
