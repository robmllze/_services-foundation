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

final class FirestoreTransactionBroker extends TransactionInterface {
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

  final _operations = <_TTransactionOperation>[];

  //
  //
  //

  @override
  void merge(Model model) {
    final operation = FirestoreMergeOperation(
      model,
      this._transaction,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void overwrite(Model model) {
    final operation = FirestoreOverwriteOperation(
      model,
      this._transaction,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void create(Model model) {
    final operation = FirestoreCreateOperation(
      model,
      this._transaction,
    );
    this._operations.add(operation);
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
    final reference = this._firestore.doc(documentPath);
    final operation = FirestoreReadOperation(
      ref,
      fromJsonOrNull,
      this._transaction,
    );
    final result = await operation.execute(reference);
    return result;
  }

  //
  //
  //

  @override
  void update(Model model) {
    final operation = FirestoreUpdateOperation(
      model,
      this._transaction,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void delete(DataRef ref) {
    final operation = FirestoreDeleteOperation(
      ref,
      this._transaction,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<List<Model>> commit() async {
    final results = <Model>[];
    try {
      for (final operation in this._operations) {
        if (operation is FirestoreReadOperation) continue;
        final documentPath = operation.ref.docPath;
        final reference = this._firestore.doc(documentPath);
        final result = await operation.execute(reference);
        if (result is Model) {
          results.add(result);
        }
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

final class FirestoreMergeOperation extends _TTransactionOperation {
  //
  //
  //

  final Model model;
  final Transaction _transaction;

  //
  //
  //

  FirestoreMergeOperation(
    this.model,
    this._transaction,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    this._transaction.set(
          reference,
          this.model.toJson(),
          SetOptions(merge: true),
        );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreOverwriteOperation extends _TTransactionOperation {
  //
  //
  //

  final Model model;
  final Transaction _transaction;

  //
  //
  //

  FirestoreOverwriteOperation(
    this.model,
    this._transaction,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    this._transaction.set(
          reference,
          this.model.toJson(),
          SetOptions(merge: false),
        );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreCreateOperation extends _TTransactionOperation {
  //
  //
  //

  final Model model;
  final Transaction _transaction;

  //
  //
  //

  FirestoreCreateOperation(
    this.model,
    this._transaction,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    this._transaction.set(
          reference,
          this.model.toJson(),
          SetOptions(merge: false),
        );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreReadOperation<TModel extends Model> extends _TTransactionOperation {
  //
  //
  //

  final TFromJsonOrNull<TModel> fromJsonOrNull;
  final Transaction _transaction;

  //
  //
  //

  FirestoreReadOperation(
    super.ref,
    this.fromJsonOrNull,
    this._transaction,
  );

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    final snapshot = await this._transaction.get(reference);
    final data = snapshot.data();
    final model = this.fromJsonOrNull(data);
    return model;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreUpdateOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;
  final Model model;

  //
  //
  //

  FirestoreUpdateOperation(
    this.model,
    this._transaction,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    this._transaction.update(reference, model.toJson());
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreDeleteOperation extends _TTransactionOperation {
  //
  //
  //

  final Transaction _transaction;

  //
  //
  //

  const FirestoreDeleteOperation(
    super.ref,
    this._transaction,
  );

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    this._transaction.delete(reference);
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TReference = DocumentReference<Map<String, dynamic>>;

typedef _TTransactionOperation = TransactionOperation<_TReference>;
