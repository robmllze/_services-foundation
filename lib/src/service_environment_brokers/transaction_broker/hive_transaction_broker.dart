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

class HiveTransactionBroker extends TransactionInterface<_TData> {
  //
  //
  //

  HiveTransactionBroker();

  //
  //
  //

  final _operations = <TransactionOperation<_TData, Null>>[];
  final _names = <String>{};

  //
  //
  //
  //

  @override
  void create(String path, _TData data) {
    this._addBox(path);
    final operation = HiveCreateOperation(path, data);
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  Future<_TData?> read(String path) async {
    final operation = HiveReadOperation(path);
    final result = await operation.execute(null);
    return result;
  }

  //
  //
  //

  @override
  void update(String path, _TData data) {
    this._addBox(path);
    final operation = HiveUpdateOperation(
      path,
      data,
    );
    this._operations.add(operation);
  }

  //
  //
  //

  @override
  void delete(String path) {
    this._addBox(path);
    final operation = HiveDeleteOperation(path);
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
        if (operation is HiveReadOperation) continue;
        final result = await operation.execute(null);
        results[operation.path] = result;
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
    for (final name in this._names) {
      await HiveBoxManager.closeBox(name);
    }
    this._names.clear();
    this._operations.clear();
  }

  //
  //
  //

  void _addBox(String path) {
    this._names.add(path);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveCreateOperation extends _TTransactionOperation {
  //
  //
  //

  final _TData data;

  //
  //
  //

  const HiveCreateOperation(
    super.path,
    this.data,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(Null reference) async {
    return HiveBoxManager.scope(this.path, (box) async {
      await box.putData(data);
      return data;
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveReadOperation extends _TTransactionOperation {
  //
  //
  //

  HiveReadOperation(
    super.path,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(Null reference) async {
    return HiveBoxManager.scope(this.path, (box) async {
      return await box.getData();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveUpdateOperation extends _TTransactionOperation {
  //
  //
  //

  final _TData data;

  //
  //
  //

  const HiveUpdateOperation(
    super.path,
    this.data,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(Null reference) async {
    return HiveBoxManager.scope(this.path, (box) async {
      await box.putData(data);
      return data;
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveDeleteOperation extends _TTransactionOperation {
  //
  //
  //

  HiveDeleteOperation(
    super.path,
  );

  //
  //
  //

  @override
  Future<_TData?> execute(Null reference) async {
    return HiveBoxManager.scope(this.path, (box) async {
      await box.deleteData();
      return null;
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TData = Map<String, dynamic>;

typedef _TTransactionOperation = TransactionOperation<_TData, Null>;
