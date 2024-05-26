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

  final FirebaseFirestore firestore;

  //
  //
  //

  FirestoreServiceBroker({
    required this.firestore,
  });

  //
  //
  //

  @override
  Stream<DataModel?> streamModel(DataRef ref) {
    final docRef = this.firestore.doc(ref.docPath);
    return docRef.snapshots().asyncMap((snapshot) async {
      final modelData = snapshot.data();
      final model = modelData != null ? DataModel(data: modelData) : null;
      return model;
    });
  }

  //
  //
  //

  @override
  Stream<Iterable<DataModel>> streamModelCollection(
    DataRef ref, {
    Object? ascendByField,
    Object? descendByField,
    int? limit,
  }) {
    final collection = this.firestore.collection(ref.collectionPath!);
    final snapshots = collection
        .baseQuery(
          ascendByField: ascendByField,
          descendByField: descendByField,
          limit: limit,
        )
        .snapshots();
    final result = snapshots.asyncMap((querySnapshot) async {
      final modelsData = querySnapshot.docs.map((e) => e.data());
      final models = modelsData.map((modelData) => DataModel(data: modelData));
      return models;
    });
    return result;
  }

  //
  //
  //

  @override
  Future<void> createModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: false));
  }

  //
  //

  //

  @override
  Future<void> setModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firestore.doc(documentPath);
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
    final modelRef = this.firestore.doc(ref.docPath);
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
    final modelRef = this.firestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.update(modelData);
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    final documentPath = ref.docPath;
    final modelRef = this.firestore.doc(documentPath);
    await modelRef.delete();
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(TransactionInterface broker) transactionHandler,
  ) async {
    await this.firestore.runTransaction((transaction) async {
      final firestoreTransaction = FirestoreTransactionBroker(
        this.firestore,
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
    final broker = FirestoreBatchTransactionBroker(this.firestore);
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
