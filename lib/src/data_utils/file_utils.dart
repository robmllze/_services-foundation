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
    required String fileId,
    required DataRef pubRef,
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
    final file = fileResults?.files.firstOrNull;
    if (file != null) {
      await serviceEnvironment.fileServiceBroker.deletePublicFile(
        pubRef: pubRef,
        fileId: fileId,
      );
      final result = serviceEnvironment.fileServiceBroker.uploadPublicFile(
        file: file,
        pubRef: pubRef,
        fileId: fileId,
      );
      final uploadedFile = await result.uploadedFile;
      // Note: It's bad practice to use generic models like this.
      final pubUpdate = GenericModel(
        data: {
          'id': pubRef.id,
          'files': {
            fileId: uploadedFile,
          },
        },
      );
      await serviceEnvironment.databaseServiceBroker.setModel(
        pubUpdate,
        pubRef,
      );
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
        await fileService.pValue.update((a) => [...?a, result.pendingUploadFile]);
      }
    }
  }
}
