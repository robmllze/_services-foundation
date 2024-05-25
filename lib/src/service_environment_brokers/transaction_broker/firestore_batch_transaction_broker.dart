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

class FirestoreBatchTransactionBroker extends TransactionInterface<_TData> {
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
  void create(String path, _TData data) {
    final docRef = _firestore.doc(path);
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
  Future<_TData?> read(String path) async {
    final docRef = this._firestore.doc(path);
    final snapshot = await docRef.get();
    return snapshot.data();
  }

  //
  //
  //

  @override
  void update(String path, _TData data) {
    final docRef = _firestore.doc(path);
    this._batch.update(docRef, data);
  }

  //
  //
  //

  @override
  void delete(String path) {
    final docRef = _firestore.doc(path);
    this._batch.delete(docRef);
  }

  //
  //
  //

  @override
  Future<Map<String, _TData?>> commit() async {
    await this._batch.commit();
    return {};
  }

  //
  //
  //

  @override
  Future<void> discard() async {
    // Do nothing.
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TData = Map<String, dynamic>;
