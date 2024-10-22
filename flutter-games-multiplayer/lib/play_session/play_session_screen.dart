// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/PlayerController.dart';
import 'package:nakama/nakama.dart';
import 'package:provider/provider.dart';

import '../game_internals/score.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlaySessionRoomScreen extends StatefulWidget {
  const PlaySessionRoomScreen({super.key});

  @override
  State<PlaySessionRoomScreen> createState() => _PlaySessionRoomScreen();
}

class _PlaySessionRoomScreen extends State<PlaySessionRoomScreen> {
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final controller = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();
    String buttonText = controller.isHost() ? "Start Game" : "Ready";
    controller.eventListener();
    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            gap,
            Center(
              child: Text(
                'Room: ${controller.lobbyCode.value}',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: controller.connectedOpponents.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 50,
                  color: Colors.amber,
                  child: Center(child: Text('Entry ${controller.connectedOpponents[index].username}')),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
            gap,
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            // if(controller.isHost()){
            //   GoRouter.of(context).go('/play/game');
            // }
            // else{
            //     if(buttonText == "Ready"){
            //       setState(() {
            //         buttonText = "Waiting for Host";
            //       });
            //     }
            //     else{
            //       setState(() {
            //         buttonText = "Ready";
            //       });
            //     }
            // }
          },
          child: Text(buttonText),
        ),
      ),
    );
  }
}
