// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // 🇽🇾🇿 & Dev
// //
// // Licencing details are in the LICENSE file in the root directory.
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import '/_common.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class FileService extends CollectionServiceInterface<ModelFileEntry> {
//   //
//   //
//   //

//   final Set<String> createdBy;

//   //
//   //
//   //

//   FileService({
//     required this.createdBy,
//     required super.serviceEnvironment,
//     required super.ref,
//     required super.limit,
//   });

//   //
//   //
//   //

//   @override
//   dynamic fromJson(Map<String, dynamic> data) {
//     return ModelFileEntry.fromJson(data);
//   }

//   //
//   //
//   //

//   @override
//   Stream<Iterable<ModelFileEntry>> stream([int? limit]) {
//     return super.serviceEnvironment.databaseQueryBroker.streamFileByCreatorId(
//           createdByAny: this.createdBy,
//           limit: limit,
//         );
//   }
// }
