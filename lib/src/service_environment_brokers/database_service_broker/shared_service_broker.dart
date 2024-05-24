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

class SharedServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  @visibleForTesting
  final SharedPreferences sharedPreferences;

  //
  //
  //

  SharedServiceBroker({
    required this.sharedPreferences,
  });

  //
  //
  //

  @override
  Future<void> createModel(Model model) async {
    final ref = model.ref!;
    final documentPath = ref.docPath;
    final existingModel = await this.readModel(ref);
    if (existingModel == null) {
      final modelString = model.toJsonString();
      await this.sharedPreferences.setString(documentPath, modelString);
    } else {
      throw Exception('Model already exists at $documentPath');
    }
  }

  //
  //
  //

  @override
  Future<void> setModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelString = model.toJsonString();
    await this.sharedPreferences.setString(documentPath, modelString);
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref, [
    TModel? Function(Model? model)? convert,
  ]) async {
    final value = this.sharedPreferences.getString(ref.docPath);
    if (value != null) {
      final data = jsonDecode(value);
      final genericModel = DataModel(data: data);
      final model = convert?.call(genericModel) ?? genericModel;
      return model as TModel?;
    }
    return null;
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelString = model.toJsonString();
    await this.sharedPreferences.setString(documentPath, modelString);
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    await this.sharedPreferences.remove(ref.docPath);
  }

  //
  //
  //

  /// Executes all operations sequentially. Does not support batch operations
  /// like Firestore.
  @override
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final results = <Model?>[];
    for (final operation in operations) {
      final dataRef = operation.model!.ref!;
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
          await this.setModel(model);
        } else {
          await this.createModel(model);
        }
        results.add(model);
      }
      // Update
      if (operation.update) {
        await this.updateModel(model);
        results.add(model);
      }
    }
    return results;
  }
}
