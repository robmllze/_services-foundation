//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:_data/lib.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class MediaUtils {
  //
  //
  //

  MediaUtils._();

  //
  //
  //

  @visibleForTesting
  static (
    Future<void>,
    ModelMediaEntry,
  ) dbNewMedia({
    required ServiceEnvironment serviceEnvironment,
    // required String fileName,
    // required Uri url,
    required String createdBy,
  }) {
    final now = DateTime.now();
    final id = IdUtils.newUuidV4();
    final media = ModelMediaEntry(
      id: id,
      createdAt: now,
      createdBy: createdBy,
      // title: fileName,
      // titleSearchable: fileName.replaceAll(r'^\w', '') .toLowerCase(),
      // url: url,
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(
        ref: Schema.mediaRef(mediaId: id),
        model: media,
      ),
    ]);
    return (
      future,
      media,
    );
  }
}
