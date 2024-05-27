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
  //

  @override
  Stream<TModel?> streamModel<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) {
    late final StreamController<TModel?> controller;

    controller = StreamController<TModel?>(
      onListen: () async {
        try {
          final box = await HiveBoxManager.openBox(ref.docPath);
          // Function to handle data setting and stream emission
          void setData(Map<String, dynamic>? data) {
            if (data != null && data.isNotEmpty) {
              final model = fromJsonOrNull(data);
              controller.add(model);
            } else {
              controller.add(null);
            }
          }

          // Get initial data and listen for updates
          final initialData = box.getData();
          setData(initialData);

          final streamSubscription = box.watchData().listen(
                setData,
                onError: controller.addError,
                onDone: controller.close,
              );

          // Ensure resources are cleaned up when the stream is no longer needed
          controller.onCancel = () async {
            await streamSubscription.cancel();
            await HiveBoxManager.closeBox(ref.docPath);
          };
        } catch (e) {
          controller.addError(e);
          await controller.close();
        }
      },
    );

    return controller.stream;
  }

  // @override
  // Stream<TModel?> streamModel<TModel extends Model>(
  //   DataRef ref,
  //   TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  // ) {
  //   Stream<TModel?> stream2Creator(Box box) {
  //     late final StreamController<TModel?> controller;
  //     void setData(Map<String, dynamic>? data) {
  //       if (data != null && data.isNotEmpty) {
  //         final model = fromJsonOrNull(data);
  //         controller.add(model);
  //       } else {
  //         controller.add(null);
  //       }
  //     }

  //     controller = StreamController<TModel?>(
  //       onListen: () async {
  //         final data = box.getData();
  //         setData(data);
  //         final streamSubscription = box.watchData().listen(
  //               setData,
  //               onError: controller.addError,
  //               onDone: controller.close,
  //             );

  //         controller.onCancel = () async {
  //           await streamSubscription.cancel();
  //           await HiveBoxManager.closeBox(ref.docPath);
  //         };
  //       },
  //     );
  //     return controller.stream;
  //   }

  //   final stream1 = Stream.fromFuture(() {
  //     return HiveBoxManager.openBox(ref.docPath);
  //   }());

  //   final stream2 = StreamMapper(stream1).map(stream2Creator).stream;
  //   return stream2;
  // }

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
    // StreamController that will manage the output stream
    final StreamController<Iterable<TModel?>> controller = StreamController<Iterable<TModel?>>();
    // Map to keep track of the active subscriptions and their latest emitted model
    final Map<int, TModel?> activeModels = {};

    // Initial fetch and setup of streams for each document
    this.streamModel(ref, ModelDataCollection.fromJsonOrNull).listen(
      (ModelDataCollection? collection) {
        if (collection?.documents == null) {
          controller.add([]);
        } else {
          // Iterate over each document reference
          for (int i = 0; i < collection!.documents!.length; i++) {
            DataRef element = collection.documents!.elementAt(i);
            // Create stream for each document
            Stream<TModel?> documentStream = this.streamModel(element, fromJsonOrNull);

            // Subscribe to the document stream
            final int index = i; // Capture the index for use in the stream listener
            documentStream.listen(
              (TModel? model) {
                // Update the model in the map
                activeModels[index] = model;
                // Emit the current snapshot of all models
                controller.add(activeModels.values.toList());
              },
              onError: controller.addError,
              onDone: () {
                // Remove the model from the map when the stream is done
                activeModels.remove(index);
                // Emit the current snapshot of all models
                controller.add(activeModels.values.toList());
              },
            );
          }
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    return controller.stream;
  }

  //
  //
  //

  // HiveService ONLY!
  Future<void> deleteCollection(DataRef ref) async {
    await HiveBoxManager.scope(
      ref.docPath,
      (box) async {
        final model = await this.readModel(ref, ModelDataCollection.fromJsonOrNull);
        if (model != null) {
          model.documents?.forEach((element) async {
            await this.deleteModel(element);
          });
          await box.deleteData();
        }
      },
    );
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
    final modelRef = model.ref!;
    // Set the model data.
    await HiveBoxManager.scope(
      modelRef.docPath,
      (box) async {
        final data = model.toJson();
        await box.mergeData(data);
      },
    );

    final collectionDocumentRef = DataRef(
      collection: ['collections'],
      id: modelRef.collectionPath!,
    );
    // Add a reference to the model to the collection document.
    await HiveBoxManager.scope(
      collectionDocumentRef.docPath,
      (box) async {
        final boxData = box.getData();
        final model = ModelDataCollection.fromJsonOrNull(boxData);
        final documents = model?.documents ?? {};
        if (model != null) {
          if (!documents.contains(modelRef)) {
            documents.add(modelRef);
            model.documents = documents;
            final data = model.toJson();
            await box.putData(data);
          }
        }
      },
    );
  }

  //
  //
  //

  @override
  Future<TModel?> readModel<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
  ) {
    return HiveBoxManager.scope(
      ref.docPath,
      (box) async {
        final box = await HiveBoxManager.openBox(ref.docPath);
        final boxData = box.getData();
        final model = fromJsonOrNull(boxData);
        return model;
      },
    );
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
    final collectionDocumentRef = DataRef(
      collection: ['collections'],
      id: ref.collectionPath!,
    );
    // Remove the reference to the model from the collection document.
    await HiveBoxManager.scope(
      collectionDocumentRef.docPath,
      (box) async {
        final boxData = box.getData();
        final model = ModelDataCollection.fromJsonOrNull(boxData);
        final documents = model?.documents ?? {};
        if (model != null) {
          if (documents.contains(ref)) {
            documents.remove(ref);
            model.documents = documents;
            final data = model.toJson();
            await box.putData(data);
          }
        }
      },
    );
    //  Delete the model data.
    await HiveBoxManager.scope(
      ref.docPath,
      (box) => box.deleteData(),
    );
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
    return letMap(this.get('data'))?.mapKeys((e) => e?.toString()).nonNullKeys;
  }

  Stream<Map<String, dynamic>?> watchData() {
    return this.watch(key: 'data').map((e) {
      return letMap(e.value)?.mapKeys((e) => e.toString()).nonNullKeys;
    });
  }

  Future<void> putData(Map<String, dynamic>? data) {
    return this.put('data', data);
  }

  Future<void> mergeData(Map<String, dynamic>? data) async {
    final a = this.getData();
    final b = data;
    final c = letMap(mergeDataDeep(a, b))?.mapKeys((e) => e?.toString()).nonNullKeys;
    await this.putData(c);
  }

  Future<void> deleteData() {
    return this.put('data', null);
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

  static Future<T> scope<T>(
    String name,
    Future<T> Function(Box box) action,
  ) async {
    final box = await openBox(name);
    final t = await action(box);
    await closeBox(name);
    return t;
  }

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
