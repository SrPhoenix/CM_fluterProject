// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nakama/nakama.dart';
import 'dart:math';

import '../settings/persistence/local_storage_settings_persistence.dart';
import '../settings/persistence/settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class PlayerController {
  static final _log = Logger('PlayerController');

  /// The persistence store that is used to save settings.
  final SettingsPersistence _store;

  /// The player's name. Used for things like high score lists.
  ValueNotifier<String> playerName = ValueNotifier('Anonymous${Random().nextInt(1000)}');

  ValueNotifier<String> lobbyCode = ValueNotifier('XAS123');

  late final NakamaBaseClient _client;
  late final Session _session;
  late final NakamaWebsocketClient _socket;
  late Match _match;
  final List<UserPresence> connectedOpponents = [];
  late bool _isHost;
  final Random _rnd = Random();

  /// Creates a new instance of [SettingsController] backed by [store].
  ///
  /// By default, settings are persisted using [LocalStorageSettingsPersistence]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  PlayerController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
        initializeNakama();
  }
  static const String _chars = 'ABCDEF1234567890';

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<void> initializeNakama() async {
    _loadStateFromPersistence();
    _client = getNakamaClient(
      host: '192.168.160.57',
      ssl: false,
      serverKey: 'defaultkey',
      httpPort: 7350,
    );

    _session = await _client.authenticateDevice(deviceId: 'Anonymous${Random().nextInt(1000)}',username: playerName.value);
    _socket = NakamaWebsocketClient.init(
      host: '192.168.160.57',
      ssl: false,
      token: _session.token,
    );
  }

  bool isHost(){
    return _isHost;
  }
  
  Future<void> createMatch() async {
    // initializeNakama();
    _isHost = true;
    lobbyCode.value = getRandomString(8);
    _match = await _socket.createMatch(lobbyCode.value);
    _socket.onMatchPresence.listen((event) {
      connectedOpponents.removeWhere((opponent) => event.leaves.any((leave) => leave.userId == opponent.userId));
      connectedOpponents.addAll(event.joins);
    });
    print('Match created with ID: ${lobbyCode.value}');
  }

  Future<void> joinMatch() async {
    // initializeNakama();
    _isHost = false;
    await _socket.joinMatch(lobbyCode.value);

    print('Joined match with ID: ${lobbyCode.value}');
    _socket.onMatchPresence.listen((event) {
      connectedOpponents.removeWhere((opponent) => event.leaves.any((leave) => leave.userId == opponent.userId));
      connectedOpponents.addAll(event.joins);
    });
  }

  Future<void> sendMessage(Map<String, dynamic> data) async {
    _socket.sendMatchData(
      matchId: lobbyCode.value,
      opCode: Int64(1),
      data: utf8.encode(json.encode(data)),
    );

  }

  void listenForMessages() {
    _socket.onMatchData.listen((data) {
      print('Received message: ${data.data}');
    });
  }

  void setPlayerName(String name) {
    playerName.value = name;
    _store.savePlayerName(playerName.value);
  }

  void setLobbyCode(String code) {
    lobbyCode.value = code.toUpperCase();
  }

  void eventListener(){
    _socket.onMatchPresence.listen((event) {
      connectedOpponents.removeWhere((opponent) => event.leaves.any((leave) => leave.userId == opponent.userId));
      connectedOpponents.addAll(event.joins);
    });
  }

    /// Asynchronously loads values from the injected persistence store.
  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getPlayerName().then((value) => playerName.value = value),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }

}
