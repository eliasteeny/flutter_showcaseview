import 'dart:collection';

import 'package:flutter/material.dart';

class DynamicKeys {
  final HashMap<String, GlobalKey> _keys = HashMap();

  GlobalKey getKey(String id) {
    if (_keys.containsKey(id)) {
      return _keys[id]!;
    }

    final key = GlobalKey();

    _keys[id] = key;

    return key;
  }

  List<GlobalKey> getAllKeys() => _keys.values.toList();
}
