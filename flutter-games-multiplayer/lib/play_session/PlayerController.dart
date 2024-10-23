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
  late bool _isHost;
  final ValueNotifier<List<UserPresence>> connectedOpponents = ValueNotifier([]);
  final String  _chars = 'ABCDEF1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  // Declare a variable to store which presence is the host
  late UserPresence hostPresence;

  /// Creates a new instance of [SettingsController] backed by [store].
  ///
  /// By default, settings are persisted using [LocalStorageSettingsPersistence]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  PlayerController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadStateFromPersistence();
    _client = getNakamaClient(
      host: '192.168.160.54',
      ssl: false,
      serverKey: 'defaultkey',
      grpcPort: 7349, // optional
      httpPort: 7350, // optional
    );
    _session = await _client.authenticateDevice(deviceId: 'AnonymousPlayer${Random().nextInt(1000)}', username: playerName.value);
    _socket = NakamaWebsocketClient.init(
      host: '127.0.0.1',
      ssl: false,
      token: _session.token,
    );
  }

  Future<void> createMatch() async {
    getUsers();
    lobbyCode.value = getRandomString(6);
    _match = await _socket.createMatch(lobbyCode.value);
    if (kDebugMode) {
      print('Match created with ID: ${lobbyCode.value}');
    }
    _isHost = true;
  }

  Future<void> joinMatch() async {
    getUsers();
    _match = await _socket.createMatch( lobbyCode.value);
    if (kDebugMode) {
      print('Joined match with ID: $lobbyCode.value');
    }
   
    _isHost = false;
  }
  bool getHost () {
    return _isHost;
  }
  void sendMessage(Map<String, dynamic> data)  {
    _socket.sendMatchData(
      matchId: lobbyCode.value,
      opCode: Int64(1),
      data: utf8.encode(jsonEncode(data)),
    );
    }

  void listenForMessages() {
    _socket.onMatchData.listen((data) {
      if (kDebugMode) {
        print('Received message: ${data.data}');
      }
    });
  }

  void getUsers() {
     _socket.onMatchPresence.listen((event) {
      connectedOpponents.value.removeWhere((opponent) => event.leaves.any((leave) => leave.userId == opponent.userId));
      connectedOpponents.value.addAll(event.joins);
    });
  }

  void setPlayerName(String name) {
    playerName.value = name;
    _store.savePlayerName(playerName.value);
  }

  void setLobbyCode(String code) {
    lobbyCode.value = code;
  }

    /// Asynchronously loads values from the injected persistence store.
  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getPlayerName().then((value) => playerName.value = value),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }

}
