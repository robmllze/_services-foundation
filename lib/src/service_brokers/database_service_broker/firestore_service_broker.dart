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

final class FirestoreServiceBroker extends DatabaseServiceInterface {
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
  Stream<Iterable<TModel>> streamModelCollection<TModel extends Model>(
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
    final r0 = snapshots.asyncMap((querySnapshot) async {
      final modelsData = querySnapshot.docs.map((e) => e.data());
      final models = modelsData.map((e) => fromJsonOrNull(e));
      return models;
    });
    final r1 = r0.map((e) => e.nonNulls);
    return r1;
  }

  //
  //
  //

  @override
  Future<void> deleteCollection({
    required DataRef collectionRef,
  }) async {
    final collection = this.firestore.collection(collectionRef.collectionPath!);
    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  //
  //
  //

  @override
  Future<void> mergeModel<TModel extends Model>(TModel model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: true));
  }

  //
  //
  //

  @override
  Future<void> overwriteModel<TModel extends Model>(TModel model) async {
    final documentPath = model.ref!.docPath;
    final modelRef = this.firestore.doc(documentPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: false));
  } 

  //
  //
  //

  @override
  Future<void> createModel<TModel extends Model>(TModel model) async {
    // NB: Does not actually check if the model already exists.
    await this.overwriteModel(model);
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
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation<Model>> operations,
  ) async {
    final broker = FirestoreBatchTransactionBroker(this.firestore);
    final results = <Model?>[];

    for (final operation in operations) {
      final ref = operation.model!.ref!;
      // Read.
      if (operation.read) {
        await broker.read(ref, DataModel.fromJsonOrNull);
        continue;
      }

      // Delete.
      if (operation.delete) {
        broker.delete(ref);
        continue;
      }

      final model = operation.model!;

      // Create.
      if (operation.create) {
        broker.create(model);
        continue;
      }

      // Update.
      if (operation.update) {
        broker.update(model);
        continue;
      }
    }
    await broker.commit();
    return results;
  }
}
