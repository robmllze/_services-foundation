//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveStorageServiceBroker extends FileServiceInterface {
  final HiveServiceBroker hiveServiceBroker;

  HiveStorageServiceBroker({
    required this.hiveServiceBroker,
  });

  @override
  Future<void> deleteFile(DataRef ref) {
    // TODO: implement deleteFile
    throw UnimplementedError();
  }

  @override
  Future<void> deletePublicFile({required DataRef pubRef, required String fileId}) {
    // TODO: implement deletePublicFile
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> downloadFile(ModelFileEntry fileEntry) async {
    return null;
  }

  @override
  Future<(Uint8List, ModelFileEntry)?> downloadFileFromRef(DataRef ref) async {
    return null;
  }

  @override
  Future<(Uri, ModelFileEntry)?> downloadUrl(DataRef ref) async {
    return null;
  }

  @override
  ({ModelFileEntry pendingUploadFile, Future<ModelFileEntry> uploadedFile}) uploadFile(
      {required PlatformFile file,
      required String currentUserPid,
      List<String> definitionPath = FileSchema.FILES,
      String? title,
      String? description,}) {
    // TODO: implement uploadFile
    throw UnimplementedError();
  }

  @override
  ({ModelFileEntry pendingUploadFile, Future<ModelFileEntry> uploadedFile}) uploadPublicFile(
      {required PlatformFile file, required DataRef pubRef, required String? fileId,}) {
    // TODO: implement uploadPublicFile
    throw UnimplementedError();
  }
}
