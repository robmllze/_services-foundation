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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CacheServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  @visibleForTesting
  final SharedPreferences sharedPreferences;

  //
  //
  //

  CacheServiceBroker({
    required this.sharedPreferences,
  });

  //
  //
  //

  @override
  Future<void> createModel(Model model, DataRef ref) async {
    final existingModel = await this.readModel(ref);
    if (existingModel == null) {
      final modelString = model.toJsonString();
      await this.sharedPreferences.setString(ref.key, modelString);
    } else {
      throw Exception('Model already exists at $ref');
    }
  }

  //
  //
  //

  @override
  Future<void> createOrUpdateModel(Model model, DataRef ref) async {
    final modelString = model.toJsonString();
    await this.sharedPreferences.setString(ref.key, modelString);
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref, [
    TModel? Function(Model? model)? convert,
  ]) async {
    final value = this.sharedPreferences.getString(ref.key);
    if (value != null) {
      final data = jsonDecode(value);
      final genericModel = GenericModel(data: data);
      final model = convert?.call(genericModel) ?? genericModel;
      return model as TModel?;
    }
    return null;
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model, DataRef ref) async {
    final modelString = model.toJsonString();
    await this.sharedPreferences.setString(ref.key, modelString);
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
    throw UnsupportedError('Not supported for SharedPreferences');
  }

  //
  //
  //

  @override
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final results = <Model?>[];
    for (final operation in operations) {
      final dataRef = operation.ref!;
      // Read.
      if (operation.read) {
        final model = await this.readModel(dataRef);
        results.add(model);
        continue;
      }
      // Delete
      if (operation.delete) {
        await this.deleteModel(dataRef);
        results.add(null);
        continue;
      }
      final model = operation.model!;
      // Create
      if (operation.create) {
        if (operation.update) {
          await this.createOrUpdateModel(model, dataRef);
        } else {
          await this.createModel(model, dataRef);
        }
        results.add(model);
      }
      // Update
      if (operation.update) {
        await this.updateModel(model, dataRef);
        results.add(model);
      }
    }
    return results;
  }

  //
  //
  //

  @override
  Stream<GenericModel?> streamModel(
    DataRef dataRef, [
    Future<void> Function(GenericModel?)? onUpdate,
  ]) {
    throw UnsupportedError('Not supported for SharedPreferences');
  }

  //
  //
  //

  @override
  Stream<Iterable<GenericModel>> streamModelCollection(
    DataRef ref, {
    Future<void> Function(Iterable<GenericModel>)? onUpdate,
    int limit = 1000,
  }) {
    throw UnsupportedError('Not supported for SharedPreferences');
  }
}
