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

final class FileUtils {
  //
  //
  //

  FileUtils._();

  //
  //
  //

  static Future<void> deleteCurrentAvatarFromBackend({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<ModelFileEntry> filesSnapshots,
  }) async {
    if (filesSnapshots.isEmpty) return;
    final avatarSnapshots = filesSnapshots.where(
      (e) => e.isFlutterImageExtension() && e.definitionPathStartsWith(FileSchema.AVATAR),
    );
    final refs = avatarSnapshots.map((e) => e.id).nonNulls.map((e) => Schema.fileRef(fileId: e));
    final deletes = refs.map((e) => serviceEnvironment.fileServiceBroker.deleteFile(e));
    await Future.wait(deletes);
  }
}
