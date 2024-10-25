import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';

class ListNotifier extends ValueNotifier<List<UserPresence>> {
  ListNotifier() : super([]);

  void addAll(List<UserPresence> list) {
    value.addAll(list);
    notifyListeners();            // here
  }
}