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

  Stream<DataModel?> streamModel(DataRef ref) {
    Stream<DataModel?> stream2Creator(Box box) {
      late final StreamController<DataModel?> controller;
      void addValue(dynamic map) {
        final data = letMap(map)?.mapKeys((e) => e.toString());
        if (data != null && data.isNotEmpty) {
          final model = DataModel(data: data);
          controller.add(model);
        } else {
          controller.add(null);
        }
      }

      controller = StreamController<DataModel?>(
        onListen: () async {
          final data = box.get('data');
          addValue(data);
          final streamSubscription = box.watch(key: 'data').listen(
            (event) {
              addValue(event.value);
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
    final stream2 = firstToSecondStream<Box, DataModel?>(
      stream1,
      stream2Creator,
    );
    return stream2;
  }

  //
  //
  //

  @override
  Stream<Iterable<DataModel?>> streamModelCollection(
    DataRef ref, {
    Future<void> Function(Iterable<DataModel?> model)? onUpdate,
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
  Future<void> createModel(Model model) async {
    final ref = model.ref!;
    final documentPath = ref.docPath;
    final existingModel = await this.readModel(ref);
    if (existingModel == null) {
      final box = await Hive.openBox(documentPath);
      await box.putAll(model.toJson());
      await box.close();
    } else {
      throw Exception('Model already exists at $documentPath');
    }
  }

  //
  //
  //

  //
  //
  //

  @override
  Future<void> setModel(Model model) async {
    // Set the model data.
    {
      await executeBoxActionOnce(model.ref!.docPath, (box) async {
        final a = box.get('data') ?? {};
        printGreen(a);
        final b = model.toJson();
        final c = mergeDataDeep(a, b);
        printGreen(c);
        await box.put('data', c);
        printLightGreen('success');
      });
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
    DataRef ref, [
    TModel? Function(Model? model)? convert,
  ]) async {
    final box = await Hive.openBox(ref.docPath);
    final data = box.toMap().mapKeys((e) => e.toString());
    if (data.isNotEmpty) {
      final genericModel = DataModel(data: data);
      final model = convert?.call(genericModel) ?? genericModel;
      return model as TModel?;
    }
    return null;
  }

  //
  //
  //

  @override
  Future<void> updateModel(Model model) async {
    final documentPath = model.ref!.docPath;
    final box = await Hive.openBox(documentPath);
    await box.putAll(model.toJson());
    await box.close();
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    await executeBoxActionOnce(ref.docPath, (box) async {
      await box.put('data', null);
    });
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
  Future<Iterable<Model?>> runBatchOperations(
    Iterable<BatchOperation> operations,
  ) async {
    final broker = HiveTransactionBroker();
    final results = <Model?>[];

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

/// Opens a box, executes an action, and immediatly closes the box. This
/// simplifies the process of opening and closing a box for a single action.
/// If a box is already open, say by some stream, it will not be closed after
/// the action is executed.
Future<void> executeBoxActionOnce(
  String documentPath,
  Future<void> Function(Box box) action,
) async {
  final wasOpen = HiveBoxManager.isBoxOpen(documentPath);
  if (!wasOpen) {
    await HiveBoxManager.openBox(documentPath);
  }
  final box = HiveBoxManager.box(documentPath)!;
  await action(box);
  if (!wasOpen) {
    await box.close();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HiveBoxManager {
  const HiveBoxManager._();

  static final Map<String, _BoxHolder> _boxes = {};

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

  static Future<void> closeBox(String name) async {
    if (isBoxOpen(name)) {
      _boxes[name]!.referenceCount--;
      if (_boxes[name]!.referenceCount == 0) {
        await _boxes[name]!.box.close();
        _boxes.remove(name);
      }
    }
  }

  static bool isBoxOpen(String name) {
    return _boxes.containsKey(name);
  }

  static Box? box(String name) {
    if (isBoxOpen(name)) {
      return _boxes[name]!.box;
    } else {
      return null;
    }
  }
}

class _BoxHolder {
  int referenceCount = 1;
  Box box;

  _BoxHolder(this.box);
}
