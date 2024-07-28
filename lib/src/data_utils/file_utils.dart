//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:file_picker/file_picker.dart';

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

  static Future<void> pickAndUploadPublicFiles({
    required ServiceEnvironment serviceEnvironment,
    required DataRef pubRef,
    List<String>? allowedExtensions,
    int compressionQuality = 30,
    String? fileId,
  }) async {
    final allowMultiple = fileId == null;
    final fileResults = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      allowCompression: true,
      compressionQuality: compressionQuality,
    );
    final files = fileResults?.files;
    if (files != null) {
      final futures = <Future>[];
      for (final file in files) {
        await serviceEnvironment.fileServiceBroker.deletePublicFile(
          pubRef: pubRef,
          fileId: fileId ?? IdUtils.newUuidV4(),
        );
        final future = serviceEnvironment.fileServiceBroker
            .uploadPublicFile(
              file: file,
              pubRef: pubRef,
              fileId: fileId,
            )
            .uploadedFile;
        futures.add(future);
      }
      await Future.wait(futures);
    }
  }

  //
  //
  //

  static Future<void> pickAndUploadFiles({
    required String currentUserPid,
    required FileService fileService,
    required ServiceEnvironment serviceEnvironment,
    List<String>? allowedExtensions,
    int compressionQuality = 30,
    bool allowMultiple = true,
  }) async {
    final fileResults = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      allowCompression: true,
      compressionQuality: compressionQuality,
    );
    if (fileResults != null) {
      for (final file in fileResults.files) {
        final result = serviceEnvironment.fileServiceBroker.uploadFile(
          file: file,
          currentUserPid: currentUserPid,
          title: 'File',
          definitionPath: FileSchema.FILES,
        );
        await Pod.cast(fileService.pValue).update((a) => [...?a, result.pendingUploadFile]);
      }
    }
  }
}
