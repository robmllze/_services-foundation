//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:hive_flutter/hive_flutter.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// TODO: We need a smart way to open and close boxes. Say we stream, the problem is,
// some async function may close the box mid-stream.

class HiveServiceBroker extends DatabaseServiceInterface {
  //
  //
  //

  const HiveServiceBroker();

  //
  //
  //r

  Stream<TModel?> streamModel<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) {
    Stream<TModel?> stream2Creator(Box box) {
      late final StreamController<TModel?> controller;
      void setData(Map<String, dynamic>? data) {
        final model = fromJsonOrNull(data);
        controller.add(model);
      }

      controller = StreamController<TModel?>(
        onListen: () async {
          final data = box.getData();
          setData(data);
          final streamSubscription = box.watchData().listen(
            (data) {
              setData(data);
            },
            onError: controller.addError,
            onDone: controller.close,
          );

          controller.onCancel = () async {
            await streamSubscription.cancel();
            await HiveBoxManager.closeBox(ref.docPath);
          };
        },
      );
      return controller.stream;
    }

    final stream1 = Stream.fromFuture(() {
      return HiveBoxManager.openBox(ref.docPath);
    }());
    final stream2 = firstToSecondStream<Box, TModel?>(
      stream1,
      stream2Creator,
    );
    return stream2;
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
    // TODO: implement streamModelCollection
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Future<void> createModel<TModel extends Model>(TModel model) async {
    // final ref = model.ref!;
    // final documentPath = ref.docPath;
    // final existingModel = await this.readModel(ref);
    // if (existingModel == null) {
    //   final box = await Hive.openBox(documentPath);
    //   await box.putAll(model.toJson());
    //   await box.close();
    // } else {
    //   throw Exception('Model already exists at $documentPath');
    // }
  }

  //
  //
  //

  //
  //
  //

  @override
  Future<void> setModel<TModel extends Model>(TModel model) async {
    // Set the model data.
    {
      final documentPath = model.ref!.docPath;
      final box = await HiveBoxManager.openBox(documentPath);
      final a = box.getData();
      final b = model.toJson();
      final c = mergeDataDeep(a, b);
      await box.putData(c);
      await HiveBoxManager.closeBox(documentPath);
    }
    // Add a reference to the model to the collection document.

    // {
    //   final collectionPath = model.ref!.collectionPath!;
    //   final ref1 = model.ref!;
    //   final ref2 = DataRef(collection: ['collections'], id: collectionPath);
    //   final documentPath = ref2.docPath;
    //   final box = await Hive.openBox(documentPath);
    //   final a = box.toMap();
    //   printRed(a);
    //   final b = ModelDataCollection(
    //     ref: ref2,
    //     documents: {ref1},
    //   ).toJson();
    //   print(b);
    //   final c = mergeDataDeep(a, b);
    //   await box.putAll(c);
    //   await box.close();
    // }
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) async {
    final box = await HiveBoxManager.openBox(ref.docPath);
    final boxData = box.getData();
    final model = fromJsonOrNull(boxData);
    await HiveBoxManager.closeBox(ref.docPath);
    return model;
  }

  //
  //
  //

  @override
  Future<void> updateModel<TModel extends Model>(TModel model) async {}

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    final documentPath = ref.docPath;
    final box = await HiveBoxManager.openBox(documentPath);
    await box.putData(null);
    await HiveBoxManager.closeBox(documentPath);
  }

  //
  //
  //

  @override
  Future<void> runTransaction(
    Future<void> Function(TransactionInterface transaction) transactionHandler,
  ) async {
    final broker = HiveTransactionBroker();
    await transactionHandler(broker);
    await broker.commit();
  }

  //
  //
  //

  @override
  Future<Iterable<TModel?>> runBatchOperations<TModel extends Model>(
    Iterable<BatchOperation<TModel>> operations,
  ) async {
    final broker = HiveTransactionBroker();
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension DataExtensionOnBox on Box {
  //
  //
  //

  Map<String, dynamic> toData() {
    final data = this.toMap();
    return data.mapKeys((e) {
      return e.toString();
    });
  }

  Map<String, dynamic>? getData() {
    return letMap(this.get('data'))?.mapKeys((e) {
      return e?.toString();
    }).nonNullKeys;
  }

  Stream<Map<String, dynamic>?> watchData() {
    return this.watch(key: 'data').map((e) {
      return letMap(e.value)?.mapKeys((e) => e.toString()).nonNullKeys;
    });
  }

  Future<void> putData(Map<String, dynamic>? data) {
    return this.put('data', data);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HiveBoxManager {
  //
  //
  //

  const HiveBoxManager._();

  //
  //
  //

  static final Map<String, _BoxHolder> _boxes = {};

  //
  //
  //

  static Future<Box> openBox(String name) async {
    if (isBoxOpen(name)) {
      _boxes[name]!.referenceCount++;
      return _boxes[name]!.box;
    } else {
      var box = await Hive.openBox(name);
      _boxes[name] = _BoxHolder(box);
      return box;
    }
  }

  //
  //
  //

  static Future<void> closeBox(String name) async {
    if (isBoxOpen(name)) {
      _boxes[name]!.referenceCount--;
      if (_boxes[name]!.referenceCount == 0) {
        await _boxes[name]!.box.close();
        _boxes.remove(name);
      }
    }
  }

  //
  //
  //

  static bool isBoxOpen(String name) {
    return _boxes.containsKey(name);
  }

  //
  //
  //

  static Box? box(String name) {
    return _boxes[name]?.box;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _BoxHolder {
  int referenceCount = 1;
  Box box;

  _BoxHolder(this.box);
}
