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

class FirestoreServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  final FirebaseFirestore firebaseFirestore;

  //
  //
  //

  FirestoreServiceBroker({
    required this.firebaseFirestore,
  });

  //
  //
  //

  @override
  Future<void> createModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firebaseFirestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: false));
  }

  //
  //

  //

  @override
  Future<void> setModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firebaseFirestore.doc(documentPath);
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
    final genericModel = DataModel(data: modelData);
    final model = modelData != null ? convert?.call(genericModel) ?? genericModel : null;
    return model as TModel?;
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firebaseFirestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.update(modelData);
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    final documentPath = ref.docPath;
    final modelRef = this.firebaseFirestore.doc(documentPath);
    await modelRef.delete();
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(TransactionInterface broker) transactionHandler,
  ) async {
    await this.firebaseFirestore.runTransaction((transaction) async {
      final firestoreTransaction = FirestoreTransactionBroker(
        this.firebaseFirestore,
        transaction,
      );
      await transactionHandler(firestoreTransaction);
      await firestoreTransaction.commit();
    });
  }

  //
  //
  //

  @override
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final broker = FirestoreBatchTransactionBroker(this.firebaseFirestore);
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
