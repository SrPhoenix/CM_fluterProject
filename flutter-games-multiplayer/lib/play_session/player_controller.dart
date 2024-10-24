// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:nakama/nakama.dart';
import 'dart:math';
import 'dart:async';

import '../settings/persistence/local_storage_settings_persistence.dart';
import '../settings/persistence/settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class PlayerController extends ChangeNotifier {
  static final _log = Logger('PlayerController');
  static final _host = "192.168.160.57";
  static const String _chars = 'ABCDEF1234567890';
  final Random _rnd = Random();

  /// The persistence store that is used to save settings.
  final SettingsPersistence _store;

  String username = 'Anonymous${Random().nextInt(1000)}';
  String lobbyCode = '';
  List<Player> connectedUsers = [];
  late bool _isHost;
  late String userId;

  late final NakamaBaseClient _client;
  late final Session _session;
  late final NakamaWebsocketClient _socket;
  late Match _match;
  late UserPresence hostPresence;
  String waitingHost = 'Waiting Host';
  late StreamSubscription<MatchPresenceEvent> presenceSubscription;
  late StreamSubscription<MatchData> dataSubscription;

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  /// Creates a new instance of [SettingsController] backed by [store].
  ///
  /// By default, settings are persisted using [LocalStorageSettingsPersistence]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  PlayerController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    connectToNakama();
  }

  Future<void> connectToNakama() async {
    await _loadStateFromPersistence();
    _client = getNakamaClient(
      host: _host,
      ssl: false,
      serverKey: 'defaultkey',
    );
  }

  Future<void> createPlayerSession() async {
    _session = await _client.authenticateDevice(
        deviceId: 'devicefrom$username', username: username);

    userId = _session.userId;
    notifyListeners();

    if (kDebugMode) {
      print("Username: $username");
      print("UserId: $userId");
    }

    _socket = NakamaWebsocketClient.init(
      host: _host,
      ssl: false,
      token: _session.token,
    );
  }

  Future<void> createMatch() async {
    lobbyCode = getRandomString(6);

    createDataListener();

    _match = await _socket.createMatch(lobbyCode);
    if (kDebugMode) {
      print('Match created with ID: $lobbyCode');
    }

    _isHost = true;
    connectedUsers.add(Player(isMe:true,isHost:  true, displayName: username));

    Map<String, dynamic> message = {'Username': username, "IsHost": true};
    sendMessage(1, message);
  }

  Future<void> joinMatch() async {
    createDataListener();
    _match = await _socket.createMatch(lobbyCode);
    if (kDebugMode) {
      print('Joined match with ID: $lobbyCode');
    }
    _isHost = false;
    connectedUsers.add(Player(isMe:true, isHost:false, displayName: username));

    _isHost = false;

    Map<String, dynamic> message = {'Username': username, "IsHost": false};
    sendMessage(1, message);
  }
  NakamaWebsocketClient getSocket() {
    return _socket;
  }
  DateTime getTimer() {
    return DateTime.now();
  }

  void createDataListener() {
    dataSubscription = _socket.onMatchData.listen((data) {
      Map<String, dynamic> message;
      final content = utf8.decode(data.data);
      if (kDebugMode) {
        print('Comntr s User ${data.presence.userId} sent $content with code ${data.opCode}');
      }
      final jsonContent = jsonDecode(content) as Map<String, dynamic>;
      switch (data.opCode) {
        //Someone asked who is in lobby
        case 1:
          message = {'Username': username, "IsHost": _isHost}; 
          for (var user in connectedUsers) {
            if (user.displayName != jsonContent["Username"] ){
              connectedUsers.add(Player(isMe:false, isHost: jsonContent["IsHost"].toString().toLowerCase() == 'true', displayName: jsonContent["Username"] as String) );
              notifyListeners();
            }
          }
          sendMessage(2, message);
          break;
        //Someone told me it is in the lobby
        case 2:
          connectedUsers.add(Player(isMe:false, isHost: jsonContent["IsHost"].toString().toLowerCase() == 'true', displayName: jsonContent["Username"] as String) );
          notifyListeners();
          //Leave match
        case 3:
          connectedUsers.removeWhere((element) => element.displayName == jsonContent["Username"]);
          notifyListeners();
          break;
          // notify players that the match is going to start
        default:
          _log.fine(() => 'controller User ${data.presence.username} sent $content and code ${data.opCode}');
      }
    });
  }


  bool getHost() {
    return _isHost;
  }

  Future<void> leaveMatch() async {
    var message = {'Username': username}; 
    sendMessage(3, message);
    
    await _socket.leaveMatch(_match.matchId);
    if (kDebugMode) {
      print('Left match with id: ${_match.matchId}');
    }
    await presenceSubscription.cancel();
    await dataSubscription.cancel();

    connectedUsers = [];
    notifyListeners();
  }

  void sendMessage(int opcode, Map<String, dynamic> data) {
    _socket.sendMatchData(
      matchId: _match.matchId,
      opCode: Int64(opcode),
      data: utf8.encode(jsonEncode(data)),
    );
  }

  void setUsername(String username) {
    this.username = username;
    _store.savePlayerName(username);
    notifyListeners();
  }

  void setLobbyCode(String code) {
    lobbyCode = code.toUpperCase();
    notifyListeners();
  }

  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getPlayerName().then((value) => username = value),
    ]);
    _log.fine(() => 'Loaded settings: $loadedValues');
    notifyListeners();
  }
}


class Player {
  final String displayName;
  final bool isMe;
  final bool isHost;

  Player( {required this.isMe, required this.isHost, required this.displayName});
}