//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:hive_flutter/hive_flutter.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HiveBoxManager {
  //
  //
  //

  const HiveBoxManager._();

  //
  //
  //

  static final Map<String, _BoxHolder> _boxes = {};

  //
  //
  //

  static Future<T> scope<T>(
    String name,
    Future<T> Function(Box box) action,
  ) async {
    final box = await openBox(name);
    final t = await action(box);
    await closeBox(name);
    return t;
  }

  //
  //
  //

  static Future<Box> openBox(String name) async {
    if (isBoxOpen(name)) {
      _boxes[name]!.referenceCount++;
      return _boxes[name]!.box;
    } else {
      var box = await Hive.openBox(name);
      _boxes[name] = _BoxHolder(box);
      return box;
    }
  }

  //
  //
  //

  static Future<void> closeBox(String name) async {
    if (isBoxOpen(name)) {
      _boxes[name]!.referenceCount--;
      if (_boxes[name]!.referenceCount == 0) {
        await _boxes[name]!.box.close();
        _boxes.remove(name);
      }
    }
  }

  //
  //
  //

  static bool isBoxOpen(String name) {
    return _boxes.containsKey(name);
  }

  //
  //
  //

  static Box? box(String name) {
    return _boxes[name]?.box;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _BoxHolder {
  int referenceCount = 1;
  Box box;

  _BoxHolder(this.box);
}
