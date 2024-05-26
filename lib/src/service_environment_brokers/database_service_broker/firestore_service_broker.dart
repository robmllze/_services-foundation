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
  Stream<TModel?> streamModel<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) {
    final docRef = this.firestore.doc(ref.docPath);
    return docRef.snapshots().asyncMap((snapshot) async {
      final modelData = snapshot.data();
      final model = fromJsonOrNull(modelData);
      return model;
    });
  }

  //
  //
  //

  @override
  Stream<Iterable<TModel?>> streamModelCollection<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull, {
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
      final models = modelsData.map((e) => fromJsonOrNull(e));
      return models;
    });
    return result;
  }

  //
  //
  //

  @override
  Future<void> createModel<TModel extends Model>(TModel model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: false));
  }

  //
  //

  //

  @override
  Future<void> setModel<TModel extends Model>(TModel model) async {
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
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) async {
    final modelRef = this.firestore.doc(ref.docPath);
    final snapshot = await modelRef.get();
    final data = snapshot.data();
    final model = fromJsonOrNull(data);
    return model;
  }

  //
  //
  //

  @override
  Future<void> updateModel<TModel extends Model>(TModel model) async {
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
  Future<Iterable<TModel?>> runBatchOperations<TModel extends Model>(
    Iterable<BatchOperation<TModel>> operations,
  ) async {
    final broker = FirestoreBatchTransactionBroker(this.firestore);
    final results = <TModel?>[];

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
