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

class MediaService extends CollectionServiceInterface<ModelMediaEntry> {
  //
  //
  //

  final Set<String> createdBy;

  //
  //
  //

  MediaService({
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
    return ModelMediaEntry.fromJson(modelData);
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelMediaEntry>> stream() {
    final s = this.serviceEnvironment.databaseQueryBroker.streamMediaByCreatorId(
          createdByAny: this.createdBy,
          limit: this.streamLimit,
        );
    return s.map((e) {
      print(e);
      return e;
    });
  }
}
