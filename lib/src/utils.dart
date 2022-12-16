import 'dart:collection';
import 'dart:ui';

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

class BlockForegroundWidget extends StatelessWidget {
  const BlockForegroundWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.black45.withOpacity(0.75),
        ),
      ),
    );
  }
}
