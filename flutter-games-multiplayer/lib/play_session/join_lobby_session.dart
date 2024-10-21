// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:multiplayer/play_session/PlayerController.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../player_progress/player_progress.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class JoinLobbySession extends StatelessWidget {
  JoinLobbySession({super.key, required this.playerName});
  String playerName ;
  static const _gap = SizedBox(height: 60);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final controller = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();
    final TextEditingController _controller = TextEditingController(text: controller.playerName.value);

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      body: ResponsiveScreen(
        squarishMainArea: ListView(
          children: [
            _gap,
            const Text(
              'Join Lobby',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 55,
                height: 1,
              ),
            ),
            _gap,
            const Text(
              'Insert Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 12,
                height: 1,
              ),
            ),
            _gap,
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 12,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                controller.setLobbyCode(value);
              },
            ),
            _gap,
            MyButton(
              onPressed: () {
                audioController.playSfx(SfxType.buttonTap);
                GoRouter.of(context).go('/play/Room');
                controller.joinMatch();
              },
              child: const Text('Join'),
            ),
            _gap,
          ],
        ),
        rectangularMenuArea: Container(), // Add appropriate widget here
      ),
    );
  }
}
