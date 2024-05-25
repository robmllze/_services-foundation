//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:hive/hive.dart';

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

  final _operations = <TransactionOperation<_TData, _TReference>>[];
  final _boxes = <String, _TReference>{};

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
    final box = this._addBox(path);
    final result = await operation.execute(box);
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
        final reference = this._getBox(operation.path);
        final result = await operation.execute(reference);
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
    await Future.wait(this._boxes.values.map((e) => e.close()));
    this._boxes.clear();
    this._operations.clear();
  }

  //
  //
  //

  _TReference _addBox(String path) {
    return this._boxes[path] = Hive.box<_TData>(path);
  }

  //
  //
  //

  _TReference _getBox(String path) {
    return this._boxes[path]!;
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
  Future<_TData?> execute(_TReference reference) async {
    await reference.put(reference.path, data);
    return null;
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

  _TData? _result;

  //
  //
  //

  @override
  Future<_TData?> execute(_TReference reference) async {
    this._result = await reference.get(reference.name);
    return this._result;
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
  Future<_TData?> execute(_TReference reference) async {
    await reference.put(reference.name, data);
    return null;
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
  Future<_TData?> execute(_TReference reference) async {
    await reference.delete(reference.name);
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TReference = Box<_TData>;

typedef _TData = Map<String, dynamic>;

typedef _TTransactionOperation = TransactionOperation<_TData, Box<_TData>>;
