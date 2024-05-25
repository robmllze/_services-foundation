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

class FirestoreTransactionBroker extends TransactionInterface<_TData> {
  //
  //
  //

  final FirebaseFirestore _firestore;
  final Transaction _transaction;

  //
  //
  //

  FirestoreTransactionBroker(
    this._firestore,
    this._transaction,
  );

  //
  //
  //

  final _operations = <TransactionOperation<_TData, _TReference>>[];

  //
  //
  //

  @override
  void create(String path, _TData data) {
    final operation = FirestoreCreateOperation(
      path,
      this._transaction,
      data,
      options: SetOptions(merge: true),
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<_TData?> read(String path) async {
    final reference = this._firestore.doc(path);
    final operation = FirestoreReadOperation(
      path,
      this._transaction,
    );
    final result = operation.execute(reference);
    return result;
  }

  //
  //
  //

  @override
  void update(String path, _TData data) {
    final operation = FirestoreUpdateOperation(
      path,
      this._transaction,
      data,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void delete(String path) {
    final operation = FirestoreDeleteOperation(
      path,
      this._transaction,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<Map<String, _TData?>> commit() async {
    final results = <String, _TData?>{};
    try {
      for (final operation in this._operations) {
        if (operation is FirestoreReadOperation) continue;
        final reference = this._firestore.doc(operation.path);
        final result = await operation.execute(reference);
        results[operation.path] = result;
      }
    } catch (e) {
      rethrow;
    } finally {
      await this.discard();
    }
    return results;
  }

  //
  //
  //

  @override
  Future<void> discard() async {
    this._operations.clear();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirestoreCreateOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;
  final _TData data;
  final SetOptions? options;

  //
  //
  //

  const FirestoreCreateOperation(
    super.path,
    this._transaction,
    this.data, {
    this.options,
  });

  //
  //
  //

  @override
  Future<_TData?> execute(_TReference reference) async {
    await this._transaction.set(
          reference,
          data,
          this.options ?? SetOptions(merge: true),
        );
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirestoreReadOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;

  //
  //
  //

  FirestoreReadOperation(
    super.path,
    this._transaction,
  );

  //
  //
  //

  _TData? _result;

  //
  //
  //

  @override
  Future<_TData?> execute(_TReference reference) async {
    final snapshot = await this._transaction.get(reference);
    this._result = snapshot.data();
    return this._result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirestoreUpdateOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;
  final _TData data;

  //
  //
  //

  const FirestoreUpdateOperation(
    super.path,
    this._transaction,
    this.data,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(_TReference reference) async {
    await this._transaction.update(reference, data);
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirestoreDeleteOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;

  //
  //
  //

  const FirestoreDeleteOperation(
    super.path,
    this._transaction,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(_TReference reference) async {
    await this._transaction.delete(reference);
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TReference = DocumentReference<_TData>;

typedef _TData = Map<String, dynamic>;

typedef _TTransactionOperation = TransactionOperation<_TData, _TReference>;
