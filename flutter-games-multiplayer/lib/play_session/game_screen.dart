// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
    late List<Player> players;
    late DateTime _startOfPlay;
    static const _celebrationDuration = Duration(milliseconds: 2000);
    bool lost =false;
    static const _preCelebrationDuration = Duration(milliseconds: 500);
    bool _duringCelebration = false;
    int upperBounder = 98;
    int lowerBounder = 82;
    late StreamSubscription dataListener;
    
    double currentHeartRate = 0.0;
    Timer? timer;

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

    // void createDataListener() {
    //   var _socket = controller.getSocket();
    //   dataListener = _socket.onMatchData.listen((data) {
    //     Map<String, dynamic> message;
    //     final content = utf8.decode(data.data);
    //     final jsonContent = jsonDecode(content) as Map<String, dynamic>;
    //     print('Game User ${data.presence.username} sent $content with code ${data.opCode}');
    //     print("Got Mssage ");
    //     switch (data.opCode) {
    //       case 3:
    //         print("game player leaved: $jsonContent");
    //         players.removeWhere((element) => element.displayName == jsonContent["Username"]);
    //         // if(players.length == 1){
    //         //   print("Send winner message:");
    //         //   final score = Score(controller.username, currentHeartRate, DateTime.now().difference(_startOfPlay));
    //         //   _playerWon(score);
    //         // }
    //           break;
    //       //Someone asked who is in lobby
    //       case 5:
    //         if(controller.getHost()){
    //           double opHeartRate = double.parse(jsonContent["Score"].toString());
    //           if(currentHeartRate > upperBounder || currentHeartRate < lowerBounder){
    //             lost =true;
    //           }

    //           print("Players : ${players.length}");
    //           for (var user in players) {
    //             if (user.displayName == jsonContent["Username"] && (opHeartRate > upperBounder || opHeartRate < lowerBounder)){
    //               if(lost){
    //                 var currDiff = min((currentHeartRate-upperBounder).abs(), (currentHeartRate-lowerBounder).abs());
    //                 var opDiff = min((opHeartRate-upperBounder).abs(), (opHeartRate-lowerBounder).abs());
    //                 print("Diffs: $currDiff,$opDiff");
    //                 if (players.length == 2){
    //                   print("Send winner message (tie):");
    //                   final score = Score(currDiff <= opDiff ? controller.username : user.displayName, currDiff <= opDiff ? currentHeartRate : opHeartRate, DateTime.now().difference(_startOfPlay));
    //                   controller.sendMessage(6, {"Username": score.playerName, "Score" : score.score, "Duration": score.duration} );
    //                   _playerWon(score);
    //                 }
    //               }
    //               controller.sendMessage(7, {"Username": user.displayName} );
    //               players.remove(user);
    //               break;
    //             }
    //           }
    //           print("Players After for: ${players.length} ");
    //           if(lost && players.length == 2){
    //             print("Send winner message (host lost):");
    //             final score = Score(players[0].displayName != controller.username ? players[0].displayName : players[1].displayName, opHeartRate, DateTime.now().difference(_startOfPlay));
    //             controller.sendMessage(6, {"Username": score.playerName, "Score" : score.score, "Duration": score.duration} );
    //             _playerWon(score);
    //           }
    //           print("Check Winner:");
    //           if (players.length == 1){
    //             print("Send winner message (host won):");
    //             final score = Score(controller.username, currentHeartRate, DateTime.now().difference(_startOfPlay));
    //             controller.sendMessage(6, {"Username": score.playerName, "Score" : score.score, "Duration": score.duration} );
    //             _playerWon(score);
    //           }
    //         }
    //         break;
    //       case 6:
    //         if(!controller.getHost()){
    //             print("Send winner message (some one won):");
    //             final score = Score.DurationString(jsonContent["Username"].toString(), jsonContent["Score"] as double, jsonContent["Duration"].toString());
    //           _playerWon(score);
    //         }
    //         break;
    //         // U lost
    //       case 7:
    //           if(controller.username == jsonContent["Username"]){
    //             lost =true;
    //             print("I LOST!!!!!!!!!!!!!!!");
    //           }
    //       default:
    //         print(() => 'Game User ${data.presence.userId} sent $content');
    //     }
    //   });
    // }

    void sendGameMessage() {
      if(players.length == 1){
          print("Send winner message (single guy):");
          final score = Score(controller.username, currentHeartRate, DateTime.now().difference(_startOfPlay));
          _playerWon(score);
        }
      if(!lost){
        double score = Random().nextDouble()* 20 + 80;
        print("Got Score: ${score}");
        if(controller.getHost()){
          currentHeartRate = score;
        }
        else{
          var message = {'Username': controller.username,"Score": score};
          controller.sendMessage(5, message);
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
      // createDataListener();
    }

    @override
    void dispose() async {
      timer?.cancel();
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
