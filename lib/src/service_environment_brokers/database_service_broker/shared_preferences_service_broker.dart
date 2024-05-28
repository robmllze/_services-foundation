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

// import '/_common.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class SharedPreferencesServiceBroker extends DatabaseServiceInterface {
//   //
//   //
//   //

//   @visibleForTesting
//   final SharedPreferences sharedPreferences;

//   //
//   //
//   //

//   SharedPreferencesServiceBroker({
//     required this.sharedPreferences,
//   });

//   //
//   //
//   //

//   @override
//   Stream<TModel?> streamModel<TModel extends Model>(
//     DataRef ref,
//     TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
//   ) {
//     // TODO: implement streamModel
//     throw UnimplementedError();
//   }

//   //
//   //
//   //

//   @override
//   Stream<Iterable<TModel>> streamModelCollection<TModel extends Model>(
//     DataRef ref,
//     TModel? Function(Map<String, dynamic>? data) fromJsonOrNull, {
//     Object? ascendByField,
//     Object? descendByField,
//     int? limit,
//   }) {
//     // TODO: implement streamModelCollection
//     throw UnimplementedError();
//   }

//   //
//   //
//   //

//   @override
//   Future<void> deleteCollection({required DataRef collectionRef}) {
//     // TODO: implement deleteCollection
//     throw UnimplementedError();
//   }

//   //
//   //
//   //

//   @override
//   Future<void> createModel<TModel extends Model>(TModel model) async {
//     final ref = model.ref!;
//     final documentPath = ref.docPath;
//     final existingModel = await this.readModel(ref, DataModel.fromJsonOrNull);
//     if (existingModel == null) {
//       final modelString = model.toJsonString();
//       await this.sharedPreferences.setString(documentPath, modelString);
//     } else {
//       throw Exception('Model already exists at $documentPath');
//     }
//   }

//   //
//   //
//   //

//   @override
//   Future<void> setModel<TModel extends Model>(TModel model) async {
//     final documentPath = model.ref!.docPath;
//     final modelString = model.toJsonString();
//     await this.sharedPreferences.setString(documentPath, modelString);
//   }

//   //
//   //
//   //

//   @override
//   Future<TModel?> readModel<TModel extends Model>(
//     DataRef ref,
//     TModel? Function(Map<String, dynamic>? data) fromJsonOrNull,
//   ) async {
//     final value = this.sharedPreferences.getString(ref.docPath);
//     if (value != null) {
//       final data = jsonDecode(value);
//       final model = fromJsonOrNull(data);
//       return model;
//     }
//     return null;
//   }

//   //
//   //
//   //

//   @override
//   Future<void> updateModel<TModel extends Model>(TModel model) async {
//     final documentPath = model.ref!.docPath;
//     final modelString = model.toJsonString();
//     await this.sharedPreferences.setString(documentPath, modelString);
//   }

//   //
//   //
//   //

//   @override
//   Future<void> deleteModel(DataRef ref) async {
//     await this.sharedPreferences.remove(ref.docPath);
//   }

//   //
//   //
//   //

//   @override
//   Future<void> runTransaction(
//     Future<void> Function(TransactionInterface broker) transactionHandler,
//   ) async {
//     final broker = SharedPreferencesTransactionBroker(
//       this.sharedPreferences,
//     );
//     await transactionHandler(broker);
//     await broker.commit();
//   }

//   //
//   //
//   //

//   @override
//   Future<Iterable<TModel?>> runBatchOperations<TModel extends Model>(
//     Iterable<BatchOperation<TModel>> operations,
//   ) async {
//     final broker = SharedPreferencesTransactionBroker(
//       this.sharedPreferences,
//     );
//     final results = <TModel?>[];

//     for (final operation in operations) {
//       final path = operation.model!.ref!.docPath;
//       // Read.
//       if (operation.read) {
//         await broker.read(path);
//         continue;
//       }

//       // Delete.
//       if (operation.delete) {
//         broker.delete(path);
//         continue;
//       }

//       final model = operation.model!;
//       final data = model.toJson();

//       // Create.
//       if (operation.create) {
//         broker.create(path, data);
//         continue;
//       }

//       // Update.
//       if (operation.update) {
//         broker.update(path, data);
//         continue;
//       }
//     }
//     await broker.commit();
//     return results;
//   }
// }
