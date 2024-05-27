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
          void $setData(Map<String, dynamic>? data) {
            if (data != null && data.isNotEmpty) {
              final model = fromJsonOrNull(data);
              controller.add(model);
            } else {
              controller.add(null);
            }
          }

          final initialData = box.getData();
          $setData(initialData);
          final streamSubscription = box.watchData().listen(
                $setData,
                onError: controller.addError,
                onDone: controller.close,
              );

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

  //
  //
  //

  @override
  Stream<Iterable<TModel>> streamModelCollection<TModel extends Model>(
    DataRef ref,
    TModel? Function(Map<String, dynamic>? data) fromJsonOrNull, {
    Object? ascendByField,
    Object? descendByField,
    int? limit,
  }) {
    final controller = StreamController<Iterable<TModel?>>();
    final subscriptions = <int, StreamSubscription<TModel?>>{};
    final models = <int, TModel?>{};

    void $emitModels() {
      controller.add(models.values);
    }

    Future<void> $cancelSubscriptions() async {
      await Future.wait(subscriptions.values.map((e) => e.cancel()));
    }

    StreamSubscription? collectionSubscription =
        this.streamModel(ref, ModelDataCollection.fromJsonOrNull).listen(
              (collection) {
                $cancelSubscriptions();
                subscriptions.clear();
                models.clear();
                final documents = collection?.documents;
                if (documents == null) {
                  controller.add([]);
                } else {
                  for (var i = 0; i < documents.length; i++) {
                    final ref = documents.elementAt(i);
                    final documentStream = this.streamModel(ref, fromJsonOrNull);

                    final index = i;
                    subscriptions[index] = documentStream.listen(
                      (model) {
                        if (model == null) {
                          models.remove(index);
                        } else {
                          models[index] = model;
                        }
                        $emitModels();
                      },
                      onError: controller.addError,
                      onDone: () {
                        models.remove(index);
                        $emitModels();
                      },
                    );
                  }
                }
              },
              onError: controller.addError,
              onDone: () {
                $cancelSubscriptions();
                controller.close();
              },
            );

    controller.onCancel = () {
      $cancelSubscriptions();
      collectionSubscription.cancel();
    };

    final r0 = controller.stream;
    final r1 = r0.map((e) => e.nonNulls);
    return r1;
  }

  //
  //
  //

  @override
  Future<void> deleteCollection({
    required DataRef collectionRef,
  }) async {
    await HiveBoxManager.scope(
      collectionRef.docPath,
      (box) async {
        final collection = await this.readModel(
          collectionRef,
          ModelDataCollection.fromJsonOrNull,
        );
        final documents = collection?.documents;
        if (documents != null) {
          // Delete all documents in the collection.
          for (final ref in documents) {
            await HiveBoxManager.scope(ref.docPath, (box) {
              return box.deleteData();
            });
          }
          // Delete the collection document.
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
    if (await _modelExists(model)) {
      throw Exception('Model already exists at ${model.ref!.docPath}');
    } else {
      await this.setModel(model);
    }
  }

  //
  //
  //

  @override
  Future<void> setModel<TModel extends Model>(TModel model) async {
    // Set the model data.
    final ref = model.ref!;
    await HiveBoxManager.scope(
      ref.docPath,
      (box) async {
        final data = model.toJson();
        await box.mergeData(data);
      },
    );

    // Add a reference to the model to the collection document.
    final falseCollectionsRef = Schema.falseCollectionsRef(
      collectionPath: ref.collectionPath!,
    );
    await HiveBoxManager.scope(
      falseCollectionsRef.docPath,
      (box) async {
        final boxData = box.getData();
        final model = ModelDataCollection.fromJsonOrNull(boxData);
        final documents = model?.documents ?? {};
        if (model != null) {
          if (!documents.contains(ref)) {
            documents.add(ref);
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
  Future<void> updateModel<TModel extends Model>(TModel model) async {
    if (await _modelExists(model)) {
      await this.setModel(model);
    } else {
      throw Exception('Model does not exist at ${model.ref!.docPath}');
    }
  }

  //
  //
  //

  Future<bool> _modelExists<TModel extends Model>(TModel model) async {
    final readModel = await this.readModel(
      model.ref!,
      DataModel.fromJsonOrNull,
    );
    final readModelData = readModel?.toJson();
    return readModelData != null && readModelData.isNotEmpty;
  }

  //
  //
  //

  @override
  Future<void> deleteModel(DataRef ref) async {
    // Remove the reference to the model from the collection document.
    final falseCollectionsRef = Schema.falseCollectionsRef(
      collectionPath: ref.collectionPath!,
    );
    await HiveBoxManager.scope(
      falseCollectionsRef.docPath,
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
