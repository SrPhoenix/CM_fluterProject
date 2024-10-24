// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/Dash_Player_Box.dart';
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
    late List<Player> players;
    late DateTime _startOfPlay;
    static const _celebrationDuration = Duration(milliseconds: 2000);

    static const _preCelebrationDuration = Duration(milliseconds: 500);
    bool _duringCelebration = false;
    
    var currentHeartRate = 0.0;
    Timer? timer;



    Future<void> _playerWon(String playerName) async {

      // TODO: replace with some meaningful score for the card game
      final score = Score(playerName, 1, DateTime.now().difference(_startOfPlay));

      // final playerProgress = context.read<PlayerProgress>();
      // playerProgress.setLevelReached(widget.level.number);

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

    void createDataListener() {
      var _socket = controller.getSocket();
      _socket.onMatchData.listen((data) {
        Map<String, dynamic> message;
      final content = utf8.decode(data.data);
      final jsonContent = jsonDecode(content) as Map<String, dynamic>;
      switch (data.opCode) {
        //Someone asked who is in lobby
        case 5:
        double score = double.parse(jsonContent["Score"].toString());
          for (var user in players) {
            if (user.displayName == jsonContent["Username"] && (score > 95 || score < 85)){
              players.remove(user);
              break;
            }
          }
          if (players.length == 1){
            _playerWon(controller.username);
          }
          break;
        default:
          print(() => 'Game User ${data.presence.userId} sent $content');
      }
      });
    }

    void sendGameMessage() {
      double score = Random().nextDouble()* 20 + 80;
      var message = {'Username': controller.username,"Score": score};
      controller.sendMessage(5, message);
      if (score > 95 || score < 85){
        for (var user in players) {
          if (user.displayName != controller.username){
            _playerWon(user.displayName);
            break;
          }

        }
        if (players.length == 1){
        }
      }
    }
    @override
    void initState() {
      super.initState();
      _startOfPlay = DateTime.now();
      timer = Timer.periodic(Duration(seconds: 1), (Timer t) => sendGameMessage());
      controller = context.read<PlayerController>();
      players = controller.connectedUsers;
    }

    @override
    void dispose() {
      timer?.cancel();
      super.dispose();
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
