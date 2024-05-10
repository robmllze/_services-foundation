//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:cloud_firestore/cloud_firestore.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirebaseFirestoreServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  final FirebaseFirestore firebaseFirestore;

  //
  //
  //

  FirebaseFirestoreServiceBroker({
    required this.firebaseFirestore,
  });

  //
  //
  //

  @override
  Future<void> createModel(Model model, DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: false));
  }

  //
  //

  //

  @override
  Future<void> setModel(Model model, DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: true));
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref, [
    TModel? Function(Model? model)? convert,
  ]) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final snapshot = await modelRef.get();
    final modelData = snapshot.data();
    final genericModel = GenericModel(data: modelData);
    final model = modelData != null ? convert?.call(genericModel) ?? genericModel : null;
    return model as TModel?;
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model, DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final modelData = model.toJson();
    await modelRef.update(modelData);
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    await modelRef.delete();
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(dynamic transaction) transactionHandler,
  ) async {
    await this.firebaseFirestore.runTransaction(transactionHandler);
  }

  //
  //
  //

  @override
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final results = <Model?>[];
    WriteBatch? writeBatch;
    for (final operation in operations) {
      final dataRef = operation.ref!;
      final docRef = this.firebaseFirestore.doc(dataRef.docPath);
      // Read.
      if (operation.read) {
        final model = await this.readModel(dataRef);
        results.add(model);
        continue;
      }

      writeBatch ??= this.firebaseFirestore.batch();

      // Delete.
      if (operation.delete) {
        writeBatch.delete(docRef);
        results.add(null);
        continue;
      }

      final model = operation.model!;
      final data = model.toJson();

      // Create.
      if (operation.create) {
        writeBatch.set(
          docRef,
          data,
          // Create and update.
          SetOptions(merge: operation.update),
        );
        results.add(model);
        continue;
      }

      // Update.
      if (operation.update) {
        writeBatch.update(docRef, data);
        results.add(model);
        continue;
      }
    }
    await writeBatch?.commit();
    return results;
  }
}
