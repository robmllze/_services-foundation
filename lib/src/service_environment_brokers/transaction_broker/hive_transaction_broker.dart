//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveTransactionBroker extends TransactionInterface {
  //
  //
  //

  final HiveServiceBroker hiveServiceBroker;

  //
  //
  //

  HiveTransactionBroker({
    required this.hiveServiceBroker,
  });

  //
  //
  //

  final _operations = <_TTransactionOperation>[];

  //
  //
  //
  //

  @override
  void create(Model model) {
    final operation = HiveCreateOperation(model);
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
    final operation = HiveReadOperation(ref, fromJsonOrNull);
    final result = await operation.execute(this.hiveServiceBroker);
    return result;
  }

  //
  //
  //

  @override
  void update(Model model) {
    final operation = HiveUpdateOperation(model);
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void delete(DataRef ref) {
    final operation = HiveDeleteOperation(ref);
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
        if (operation is HiveReadOperation) continue;
        final result = await operation.execute(this.hiveServiceBroker);
        if (result is Model) {
          results.add(result);
        }
      }
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

class HiveCreateOperation extends _TTransactionOperation {
  //
  //
  //

  final Model model;

  //
  //
  //

  HiveCreateOperation(
    this.model,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    await reference.createModel(model);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveReadOperation<TModel extends Model> extends _TTransactionOperation {
  //
  //
  //

  final TFromJsonOrNull<TModel> fromJsonOrNull;

  //
  //
  //

  const HiveReadOperation(
    super.ref,
    this.fromJsonOrNull,
  );

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    final model = await reference.readModel(ref, fromJsonOrNull);
    return model;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveUpdateOperation extends _TTransactionOperation {
  //
  //
  //

  final Model model;

  //
  //
  //

  HiveUpdateOperation(
    this.model,
  ) : super(model.ref!);

  //
  //
  //

  @override
  Future<dynamic> execute(_TReference reference) async {
    await reference.updateModel(model);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveDeleteOperation extends _TTransactionOperation {
  //
  //
  //

  const HiveDeleteOperation(
    super.ref,
  );

  //
  //
  //

  @override
  Future<void> execute(_TReference reference) async {
    await reference.deleteModel(this.ref);
    return;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TReference = HiveServiceBroker;

typedef _TTransactionOperation = TransactionOperation<_TReference>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

DataRef dataRefFromPath(List<String> path) {
  final temp = path.join('/').split('/');
  if (temp.isNotEmpty) {
    final length = temp.length;
    if (length.isEven) {
      final collection = temp.sublist(0, length - 1);
      final id = temp.last;
      return DataRefModel(
        id: id,
        collection: collection,
      );
    } else {
      final collection = temp;
      return DataRefModel(
        id: null,
        collection: collection,
      );
    }
  } else {
    return DataRefModel();
  }
}
