// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/dash_player_box.dart';
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

Widget _buildRectangularMenuArea(BuildContext context, PlayerController playerController, AudioController audioController, String buttonText) {
  if (playerController.getHost()) {
    return MyButton(
      onPressed: () {
        audioController.playSfx(SfxType.buttonTap);
        print("Pressed Start Game");
        playerController.sendMessage(4, {'Username': playerController.username});
        GoRouter.of(context).go('/play/Game');
      },
      child: Text(buttonText),
    );
  }
  else {
    return SizedBox.shrink(
      child: Text(playerController.waitingHost),
    );
  }
}

class _PlaySessionRoomScreen extends State<PlaySessionRoomScreen> {
  late PlayerController controller;
  late StreamSubscription dataListener;
  void createDataListener() {
    dataListener = controller.getSocket().onMatchData.listen((data) {
      final content = utf8.decode(data.data);
      // print('widget User ${data.presence.userId} sent $content with code ${data.opCode}');
      switch (data.opCode) {
        //Someone asked who is in lobby
        case 4:
          GoRouter.of(context).go('/play/Game');
          break;
        default:
          // print(() => 'widget User ${data.presence.username} sent $content and code ${data.opCode}');
      }
    });
  }
  @override
  void initState() {
    super.initState();
    controller = context.read<PlayerController>();
    createDataListener();
  }

  @override
  void dispose() async {
    super.dispose();
    await dataListener.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final audioController = context.watch<AudioController>();
    final playerController = context.watch<PlayerController>();
    String buttonText = playerController.getHost() ? 'Start Game' : 'Ready';
    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${playerController.username}',
                  style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                ),
                IconButton(
                  icon: Icon(Icons.door_front_door, color: Colors.red,),
                  onPressed: () {
                    playerController.sendMessage(3, {'Username': playerController.username});
                    GoRouter.of(context).go('/play/joinRoom');
                  },
                ),
              ],
            ),
            gap,
            Center(
              child: Text(
                'Room: ${playerController.lobbyCode}',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
            Expanded(
              child: Align(
                alignment: const Alignment(0, -0.5),
                child: Stack(
                  fit: StackFit.loose,
                  alignment: Alignment.topLeft,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 0,
                        bottom: 32,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 174,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3,
                      ),
                      itemCount: playerController.connectedUsers.length,
                      itemBuilder: (context, index) {
                        final player = playerController.connectedUsers[index];
                        return DashPlayerBox(
                          playerName: player.displayName,
                          isMe: player.isMe,
                          isHost: player.isHost,
                        );
                      },
                    ),
                    Transform.translate(
                      offset: Offset(20, -32),
                      child: Text(
                        '${playerController.connectedUsers.length} Joined',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ListView.builder(
            //   shrinkWrap: true,
            //     itemCount: playerController.connectedUsers.length,
            //     itemBuilder: (context, index) {
            //       final user = playerController.connectedUsers[index];
            //       return ListTile(
            //         title: Text(user),
            //       );
            //     },
            //   ),
          ],
        ),
        rectangularMenuArea: _buildRectangularMenuArea( context,  playerController,  audioController, buttonText),
      ),
    );
  }
}