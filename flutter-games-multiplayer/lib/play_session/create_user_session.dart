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

class CreateUserSession extends StatelessWidget {
  CreateUserSession({super.key});
  String playerName =  "AnonymousPlayer${Random().nextInt(1000)}";
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
              'Create User Name',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 55,
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
                controller.setPlayerName(value);
              },
            ),
            _gap,
            MyButton(
              onPressed: () async {
                audioController.playSfx(SfxType.buttonTap);
                await controller.createMatch();
                GoRouter.of(context).go('/play/room', extra: {'Name': controller.playerName.value});
              },
              child: const Text('Create Lobby'),
            ),
            _gap,
            MyButton(
              onPressed: () {
                audioController.playSfx(SfxType.buttonTap);
                GoRouter.of(context).go('/play/joinRoom', extra: {'Name': controller.playerName.value});

              },
              child: const Text('Join Lobby'),
            ),
            _gap,
          ],
        ),
        rectangularMenuArea: Container(), // Add appropriate widget here
      ),
    );
  }
}
