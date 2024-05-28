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

class FirestoreBatchTransactionBroker extends TransactionInterface {
  //
  //
  //

  final FirebaseFirestore _firestore;
  late final _batch = this._firestore.batch();

  //
  //
  //

  FirestoreBatchTransactionBroker(this._firestore);

  //
  //
  //

  @override
  void create(Model model) {
    final documentPath = model.ref!.docPath;
    final docRef = this._firestore.doc(documentPath);
    final data = model.toJson();
    this._batch.set(
          docRef,
          data,
          SetOptions(merge: true),
        );
  }

  //
  //
  //

  @override
  Future<TModel?> read<TModel extends Model>(
    DataRef ref,
    TFromJsonOrNull<TModel> fromJsonOrNull,
  ) async {
    final documentPath = ref.docPath;
    final docRef = this._firestore.doc(documentPath);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    final model = fromJsonOrNull(data);
    return model;
  }

  //
  //
  //

  @override
  void update(Model model) {
    final documentPath = model.ref!.docPath;
    final docRef = this._firestore.doc(documentPath);
    final data = model.toJson();
    this._batch.update(
          docRef,
          data,
        );
  }

  //
  //
  //

  @override
  void delete(DataRef ref) {
    final documentPath = ref.docPath;
    final docRef = this._firestore.doc(documentPath);
    this._batch.delete(docRef);
  }

  //
  //
  //

  @override
  Future<List<Model>> commit() async {
    await this._batch.commit();
    return [];
  }

  //
  //
  //

  @override
  Future<void> discard() async {
    // Do nothing.
  }
}
