//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:hive/hive.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  const HiveServiceBroker();

  //
  //
  //

  @override
  Future<void> createModel(Model model) async {
    final ref = model.ref!;
    final documentPath = ref.docPath;
    final existingModel = await this.readModel(ref);
    if (existingModel == null) {
      final box = await Hive.openBox(documentPath);
      await box.putAll(model.toJson());
      await box.close();
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
    final box = await Hive.openBox(documentPath);
    await box.putAll(model.toJson());
    await box.close();
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref, [
    TModel? Function(Model? model)? convert,
  ]) async {
    final box = await Hive.openBox(ref.docPath);
    final data = box.toMap().mapKeys((e) => e.toString());
    if (data.isNotEmpty) {
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
    final box = await Hive.openBox(documentPath);
    box.putAll(model.toJson());
    await box.close();
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    final documentPath = ref.docPath;
    final box = await Hive.openBox(documentPath);
    await box.deleteFromDisk();
    await box.close();
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(TransactionInterface transaction) transactionHandler,
  ) async {
    final broker = HiveTransactionBroker();
    await transactionHandler(broker);
    await broker.commit();
  }

  //
  //
  //

  @override
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final broker = HiveTransactionBroker();
    final results = <Model?>[];

    for (final operation in operations) {
      final path = operation.model!.ref!.docPath;
      // Read.
      if (operation.read) {
        await broker.read(path);
        continue;
      }

      // Delete.
      if (operation.delete) {
        broker.delete(path);
        continue;
      }

      final model = operation.model!;
      final data = model.toJson();

      // Create.
      if (operation.create) {
        broker.create(path, data);
        continue;
      }

      // Update.
      if (operation.update) {
        broker.update(path, data);
        continue;
      }
    }
    await broker.commit();
    return results;
  }
}
