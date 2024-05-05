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
import 'package:firebase_storage/firebase_storage.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirebaseStorageServiceBroker extends FileServiceInterface {
  //
  //
  //

  final DatabaseServiceInterface databaseService;
  final FirebaseStorage firebaseStorage;

  //
  //
  //

  FirebaseStorageServiceBroker({
    required this.databaseService,
    required this.firebaseStorage,
  });

  //
  //
  //

  @override
  Future<(Uri, ModelFileEntry)?> downloadUrl(DataRef ref) async {
    try {
      final fileEntry = ModelFileEntry.from(await databaseService.readModel(ref));
      final storagePath = fileEntry.storagePath!;
      var downloadUrl = fileEntry.downloadUrl;
      if (downloadUrl != null) {
        return (downloadUrl, fileEntry);
      } else {
        final storageRef = this.firebaseStorage.ref(storagePath);
        downloadUrl = Uri.parse(await storageRef.getDownloadURL());
        return (downloadUrl, fileEntry);
      }
    } catch (_) {
      return null;
    }
  }

  //
  //
  //

  @override
  Future<(Uint8List, ModelFileEntry)?> downloadFile(DataRef ref) async {
    try {
      final fileEntry = ModelFileEntry.from(await databaseService.readModel(ref));
      final storagePath = fileEntry.storagePath!;
      final storageRef = this.firebaseStorage.ref(storagePath);
      final data = (await storageRef.getData())!;
      return (data, fileEntry);
    } catch (_) {
      return null;
    }
  }

  //
  //
  //

  @override
  Future<void> uploadFile({
    required PlatformFile file,
    String? createdBy,
    String? title,
    String? description,
  }) async {
    final fileId = IdUtils.newUuidV4();
    final ref = Schema.fileRef(fileId: fileId);
    final now = DateTime.now();
    final storagePath = ref.docPath;
    final storageRef = this.firebaseStorage.ref(storagePath);
    final fileEntry1 = ModelFileEntry(
      id: ref.id!,
      createdAt: now,
      createdBy: createdBy,
      storagePath: storagePath,
      title: title,
      searchableTitle: title,
      extension: file.extension,
      description: description,
      size: file.size,
      name: file.name,
      path: [],
    );
    await databaseService.createModel(fileEntry1, ref);
    final task = await storageRef.putData(file.bytes!);
    final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
    final fileEntry2 = ModelFileEntry(
      // size: task.metadata?.size,
      // name: task.metadata?.name,
      downloadUrl: downloadUrl,
    );
    await databaseService.updateModel(fileEntry2, ref);
  }

  //
  //
  //

  @override
  Future<void> deleteFile(DataRef ref) async {
    final fileEntry = ModelFileEntry.from(await databaseService.readModel(ref));
    final storagePath = fileEntry.storagePath!;
    final storageRef = this.firebaseStorage.ref(storagePath);
    await storageRef.delete();
    await databaseService.deleteModel(ref);
  }
}
