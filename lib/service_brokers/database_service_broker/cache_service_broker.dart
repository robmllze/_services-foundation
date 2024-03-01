//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// X|Y|Z & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:shared_preferences/shared_preferences.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CacheServiceBroker extends DatabaseServiceInterface<Model> {
  //
  //
  //

  @visibleForTesting
  final SharedPreferences sharedPreferences;

  //
  //
  //

  CacheServiceBroker({required this.sharedPreferences});

  //
  //
  //

  @override
  Future<void> setModel(Model model, DataRef ref) async {
    final value = model.toJsonString();
    await this.sharedPreferences.setString(ref.key, value);
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model, DataRef ref) async {
    final value = model.toJsonString();
    await this.sharedPreferences.setString(ref.key, value);
  }

  //
  //
  //

  @override
  Future<GenericModel?> getModel(DataRef ref) async {
    final value = this.sharedPreferences.getString(ref.key);
    if (value != null) {
      return GenericModel(jsonDecode(value));
    }
    return null;
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    await this.sharedPreferences.remove(ref.key);
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(dynamic) transactionHandler,
  ) async {
    throw UnsupportedError("Not supported for SharedPreferences");
  }

  //
  //
  //

  @override
  Future<void> batchWrite(
    Iterable<BatchWriteOperation<Model>> writes,
  ) async {
    for (final write in writes) {
      final dataRef = write.ref;
      final model = write.model;
      if (model != null) {
        final value = model.toJsonString();
        await this.sharedPreferences.setString(dataRef.key, value);
      } else if (write.delete) {
        await this.sharedPreferences.remove(dataRef.key);
      }
    }
  }

  //
  //
  //

  @override
  Stream<GenericModel?> streamModelData(
    DataRef dataRef, [
    Future<void> Function(GenericModel?)? onUpdate,
  ]) {
    throw UnsupportedError("Not supported for SharedPreferences");
  }

  //
  //
  //

  @override
  Stream<Iterable<GenericModel>> streamModelDataCollection(
    DataRef ref, {
    Future<void> Function(Iterable<GenericModel>)? onUpdate,
    int limit = 1000,
  }) {
    throw UnsupportedError("Not supported for SharedPreferences");
  }
}
