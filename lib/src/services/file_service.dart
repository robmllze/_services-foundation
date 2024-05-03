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

class FileService extends CollectionServiceInterface<ModelFileEntry> {
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
    required super.streamLimit,
  });

  //
  //
  //

  @override
  dynamic fromJson(Map<String, dynamic> modelData) {
    return ModelFileEntry.fromJson(modelData);
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> stream() {
    return super.serviceEnvironment.databaseQueryBroker.streamFileByCreatorId(
          createdByAny: this.createdBy,
          limit: this.streamLimit,
        );
  }
}
