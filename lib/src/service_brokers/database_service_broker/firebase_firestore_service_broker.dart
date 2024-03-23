//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:cloud_firestore/cloud_firestore.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirebaseFirestoreServiceBroker extends DatabaseServiceInterface<Model> {
  //
  //
  //

  @visibleForTesting
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
  Future<void> setModel(Model model, DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final modelData = model.toJson();
    await modelRef.set(modelData, SetOptions(merge: true));
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
  Future<GenericModel?> getModel(DataRef ref) async {
    final modelRef = this.firebaseFirestore.doc(ref.docPath);
    final snapshot = await modelRef.get();
    final modelData = snapshot.data();
    final model = modelData != null ? GenericModel(modelData) : null;
    return model;
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
    Future<void> Function(dynamic) transactionHandler,
  ) async {
    await this.firebaseFirestore.runTransaction((transaction) async {
      await transactionHandler(transaction);
    });
  }

  //
  //
  //

  @override
  Future<void> batchWrite(
    Iterable<BatchWriteOperation<Model>> writes,
  ) async {
    final batch = this.firebaseFirestore.batch();
    for (final write in writes) {
      final dataRef = write.ref;
      final docRef = this.firebaseFirestore.doc(dataRef.docPath);
      if (write.model != null) {
        final data = write.model?.toJson();
        if (data != null) {
          if (write.overwriteExisting) {
            batch.set(docRef, data, SetOptions(merge: write.mergeExisting));
          } else {
            batch.update(docRef, data);
          }
        }
      } else if (write.delete) {
        batch.delete(docRef);
      }
    }
    await batch.commit();
  }

  //
  //
  //

  @override
  Stream<GenericModel?> streamModel(
    DataRef dataRef, [
    Future<void> Function(GenericModel?)? onUpdate,
  ]) {
    final docRef = this.firebaseFirestore.doc(dataRef.docPath);
    return docRef.snapshots().asyncMap((snapshot) async {
      final modelData = snapshot.data();
      final model = modelData != null ? GenericModel(modelData) : null;
      await onUpdate?.call(model);
      return model;
    });
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
    final collectionRef = this.firebaseFirestore.collection(ref.collectionPath!).limit(limit);
    return collectionRef.snapshots().asyncMap((querySnapshot) async {
      final modelsData = querySnapshot.docs.map((e) => e.data());
      final models = modelsData.map((e) => GenericModel(e)).toList();
      await onUpdate?.call(models);
      return models;
    });
  }
}
