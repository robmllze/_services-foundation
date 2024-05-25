//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPreferencesTransactionBroker implements TransactionInterface<_TData> {
  //
  //
  //

  final SharedPreferences _sharedPreferences;

  //
  //
  //

  SharedPreferencesTransactionBroker(this._sharedPreferences);

  //
  //
  //

  final _operations = <_TTransactionOperation>[];

  //
  //
  //

  @override
  void create(String path, _TData data) {
    final operation = SharedPreferencesCreateOperation(
      path,
      data,
      this._sharedPreferences,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<_TData?> read(String path) async {
    final operation = SharedPreferencesReadOperation(
      path,
      this._sharedPreferences,
    );
    final result = await operation.execute(path);
    return result;
  }

  //
  //
  //

  @override
  void update(String path, _TData data) {
    final operation = SharedPreferencesUpdateOperation(
      path,
      data,
      this._sharedPreferences,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void delete(String key) {
    final operation = SharedPreferencesDeleteOperation(
      key,
      this._sharedPreferences,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<Map<String, _TData?>> commit() async {
    final results = <String, _TData?>{};
    try {
      for (final operation in this._operations) {
        if (operation is HiveReadOperation) continue;
        final reference = operation.path;
        final result = await operation.execute(reference);
        results[operation.path] = result;
      }
    } finally {
      await this.discard();
    }
    return results;
  }

  //
  //
  //

  @override
  Future<void> discard() async {
    this._operations.clear();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPreferencesCreateOperation extends _TTransactionOperation {
  //
  //
  //

  final _TData data;
  final SharedPreferences sharedPreferences;

  //
  //
  //

  const SharedPreferencesCreateOperation(
    super.path,
    this.data,
    this.sharedPreferences,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(String reference) async {
    final encoded = json.encode(data);
    if (await this.sharedPreferences.setString(reference, encoded)) {
      return data;
    }
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPreferencesReadOperation extends _TTransactionOperation {
  //
  //
  //

  final SharedPreferences sharedPreferences;

  //
  //
  //

  const SharedPreferencesReadOperation(
    super.path,
    this.sharedPreferences,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(String reference) async {
    final data = this.sharedPreferences.getString(reference);
    final decoded = data != null ? json.decode(data) : null;
    final result = (decoded as Map?)?.mapKeys((e) => e.toString());
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPreferencesUpdateOperation extends _TTransactionOperation {
  //
  //
  //

  final _TData data;
  final SharedPreferences sharedPreferences;

  //
  //
  //

  const SharedPreferencesUpdateOperation(
    super.path,
    this.data,
    this.sharedPreferences,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(String reference) async {
    final encoded = json.encode(data);
    if (await this.sharedPreferences.setString(reference, encoded)) {
      return data;
    }
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPreferencesDeleteOperation extends _TTransactionOperation {
  //
  //
  //

  final SharedPreferences sharedPreferences;

  //
  //
  //

  const SharedPreferencesDeleteOperation(
    super.path,
    this.sharedPreferences,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(String reference) async {
    await this.sharedPreferences.remove(reference);
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TData = Map<String, dynamic>;

typedef _TTransactionOperation = TransactionOperation<_TData, String>;
