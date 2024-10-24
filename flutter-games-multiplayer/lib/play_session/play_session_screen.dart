// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/player_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:provider/provider.dart';

import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlaySessionRoomScreen extends StatefulWidget {
  const PlaySessionRoomScreen({super.key});

  @override
  State<PlaySessionRoomScreen> createState() => _PlaySessionRoomScreen();
}

class _PlaySessionRoomScreen extends State<PlaySessionRoomScreen> {


  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerController = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();
    String buttonText = playerController.getHost() ? 'Start Game' : 'Ready';
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
                'Room: ${playerController.lobbyCode}',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
            ListView.builder(
              shrinkWrap: true,
                itemCount: playerController.connectedUsers.length,
                itemBuilder: (context, index) {
                  final user = playerController.connectedUsers[index];
                  return ListTile(
                    title: Text(user),
                  );
                },
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);
            // GoRouter.of(context).go('/');
            // controller.sendMessage({"hello": "world"});
            // if (controller.getHost()) {
            //   GoRouter.of(context).go('/play/Game');
            // }else{
            //     setState(() {
            //     // Change the button text on button click
            //     buttonText = 'Waiting Host';
            //   });
            // }
          },
          child: Text(buttonText),
        ),
      ),
    );
  }
}
