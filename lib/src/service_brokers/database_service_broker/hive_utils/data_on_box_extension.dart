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

extension DataOnBoxExtension on Box {
  //
  //
  //

  Map<String, dynamic> toData() {
    final data = this.toMap();
    return data.mapKeys((e) {
      return e.toString();
    });
  }

  Map<String, dynamic>? getData() {
    return letMap(this.get('data'))?.mapKeys((e) => e?.toString()).nonNullKeys;
  }

  Stream<Map<String, dynamic>?> watchData() {
    return this.watch(key: 'data').map((e) {
      return letMap(e.value)?.mapKeys((e) => e.toString()).nonNullKeys;
    });
  }

  Future<void> putData(Map<String, dynamic>? data) {
    return this.put('data', data);
  }

  Future<void> mergeData(Map<String, dynamic>? data) async {
    final a = this.getData();
    final b = data;
    final c = letMap(mergeDataDeep(a, b))?.mapKeys((e) => e?.toString()).nonNullKeys;
    await this.putData(c);
  }

  Future<void> deleteData() {
    return this.put('data', null);
  }
}
