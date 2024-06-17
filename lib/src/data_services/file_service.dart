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

final class FileService extends CollectionServiceInterface<ModelFileEntry> {
  //
  //
  //

  final Set<String> createdBy;

  //
  //
  //

  FileService({
    required this.createdBy,
    required super.serviceEnvironment,
    required super.ref,
    required super.limit,
  });

  //
  //
  //

  @override
  ModelFileEntry? fromJsonOrNull(Map<String, dynamic>? data) {
    return ModelFileEntry.fromJsonOrNull(data);
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> stream([int? limit]) {
    return super.serviceEnvironment.databaseQueryBroker.streamFilesByCreatorId(
          createdByAny: this.createdBy,
          limit: limit,
        );
  }
}
