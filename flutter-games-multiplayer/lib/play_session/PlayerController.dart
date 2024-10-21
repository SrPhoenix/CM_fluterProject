// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
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

  /// Creates a new instance of [SettingsController] backed by [store].
  ///
  /// By default, settings are persisted using [LocalStorageSettingsPersistence]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  PlayerController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    _loadStateFromPersistence();
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
