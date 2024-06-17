// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // 🇽🇾🇿 & Dev
// //
// // Licencing details are in the LICENSE file in the root directory.
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// import '/_common.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// final class SharedPreferencesTransactionBroker implements TransactionInterface<Model> {
//   //
//   //
//   //

//   final SharedPreferences sharedPreferences;

//   //
//   //
//   //

//   SharedPreferencesTransactionBroker({
//     required this.sharedPreferences,
//   });

//   //
//   //
//   //

//   final _operations = <_TTransactionOperation>[];

//   //
//   //
//   //

//   @override
//   void create(Model model) {
//     final ref = model.ref!;
//     final operation = SharedPreferencesCreateOperation(
//       path,
//       data,
//       this.sharedPreferences,
//     );
//     this._operations.add(operation);
//   }

//   @override
//   void create(Model model) {
//     final operation = HiveCreateOperation(model);
//     this._operations.add(operation);
//   }

//   //
//   //
//   //

//   @override
//   Future<_TData?> read(String path) async {
//     final operation = SharedPreferencesReadOperation(
//       path,
//       this.sharedPreferences,
//     );
//     final result = await operation.execute(path);
//     return result;
//   }

//   //
//   //
//   //

//   @override
//   void update(String path, _TData data) {
//     final operation = SharedPreferencesUpdateOperation(
//       path,
//       data,
//       this.sharedPreferences,
//     );
//     this._operations.add(operation);
//   }

//   //
//   //
//   //

//   @override
//   void delete(String key) {
//     final operation = SharedPreferencesDeleteOperation(
//       key,
//       this.sharedPreferences,
//     );
//     this._operations.add(operation);
//   }

//   //
//   //
//   //

//   @override
//   Future<Map<String, _TData?>> commit() async {
//     final results = <String, _TData?>{};
//     try {
//       for (final operation in this._operations) {
//         if (operation is HiveReadOperation) continue;
//         final reference = operation.path;
//         final result = await operation.execute(reference);
//         results[operation.path] = result;
//       }
//     } finally {
//       await this.discard();
//     }
//     return results;
//   }

//   //
//   //
//   //

//   @override
//   Future<void> discard() async {
//     this._operations.clear();
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class SharedPreferencesCreateOperation extends _TTransactionOperation {
//   //
//   //
//   //

//   final Model model;

//   //
//   //
//   //

//   SharedPreferencesCreateOperation(
//     this.model,
//   ) : super(model.ref!);

//   //
//   //
//   //

//   @override
//   Future<dynamic> execute(_TReference reference) async {
//     final key = model.ref!.docPath;
//     final encoded = model.toJsonString();
//     await reference.setString(key, encoded);
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class SharedPreferencesReadOperation<TModel extends Model> extends _TTransactionOperation {
//   //
//   //
//   //

//   final TModel? Function(String? otherData) fromJsonStringOrNull;

//   //
//   //
//   //

//   const SharedPreferencesReadOperation(
//     super.ref,
//     this.fromJsonStringOrNull,
//   );

//   //
//   //
//   //

//   @override
//   Future<dynamic> execute(_TReference reference) async {
//     final key = this.ref.docPath;
//     final encoded = reference.getString(key);
//     final model = fromJsonStringOrNull(encoded);
//     return model;
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class SharedPreferencesUpdateOperation extends _TTransactionOperation {
//    //
//   //
//   //

//   final Model model;

//   //
//   //
//   //

//   SharedPreferencesCreateOperation(
//     this.model,
//   ) : super(model.ref!);

//   //
//   //
//   //

//   @override
//   Future<dynamic> execute(_TReference reference) async {
//     final key = model.ref!.docPath;
//     final encoded = model.toJsonString();
//     await reference.setString(key, encoded);
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class SharedPreferencesDeleteOperation extends _TTransactionOperation {
//   //
//   //
//   //

//   final SharedPreferences sharedPreferences;

//   //
//   //
//   //

//   const SharedPreferencesDeleteOperation(
//     super.path,
//     this.sharedPreferences,
//   );

//   //
//   //
//   //

//   @override
//   Future<dynamic> execute(_TReference reference) async {
//     await this.sharedPreferences.remove(reference);
//     return null;
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// typedef _TReference = SharedPreferences;

// typedef _TTransactionOperation = TransactionOperation<_TReference>;
