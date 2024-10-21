// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nakama/nakama.dart';
import 'package:provider/provider.dart';

import '../game_internals/score.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlaySessionRoomScreen extends StatefulWidget {
  final String playerName;
  const PlaySessionRoomScreen({super.key, required this.playerName});

  @override
  State<PlaySessionRoomScreen> createState() => _PlaySessionRoomScreen();
}

class _PlaySessionRoomScreen extends State<PlaySessionRoomScreen> {
  late final String playerName;
  late final NakamaBaseClient _client;
  late final Session _session;
  late final NakamaWebsocketClient _socket;
  String? _matchId;
  
  @override
  void initState() {
    super.initState();
    playerName = widget.playerName;
  }

Future<void> initializeNakama() async {
    _client = getNakamaClient(
      host: '127.0.0.1',
      ssl: false,
      serverKey: 'defaultkey',
      grpcPort: 7349, // optional
      httpPort: 7350, // optional
    );

    _session = await _client.authenticateDevice(username: playerName, deviceId: "RandomDeviceId${Random().nextInt(1000)}");
    _socket = NakamaWebsocketClient.init(
      host: '127.0.0.1',
      ssl: false,
      token: _session.token,
    );
    final match = await _socket.createMatch();
    _matchId = match.matchId;
    print('Match created with ID: ${_matchId}');


  }

  Future<void> joinMatch(String matchId) async {
    await _socket.joinMatch(matchId);
    setState(() {
      _matchId = matchId;
    });
    print('Joined match with ID: $matchId');
  }

  Future<void> sendMessage(Map<String, dynamic> data) async {
    if (_matchId != null) {
      _socket.sendMatchData(
      matchId: _matchId!,
      opCode: Int64(1),
      data: utf8.encode(jsonEncode(data)),
    );
    }
  }

  void listenForMessages() {
    _socket.onMatchData.listen((data) {
      print('Received message: ${data.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

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
                'Room: $_matchId',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            GoRouter.of(context).go('/');
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
