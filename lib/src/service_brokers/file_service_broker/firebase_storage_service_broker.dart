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
  Future<void> uploadFile(
    DataRef ref,
    Uint8List bytes, {
    List<String>? falsePath,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    final storagePath = ref.docPath;
    final storageRef = this.firebaseStorage.ref(storagePath);
    final task = await storageRef.putData(bytes);
    final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
    final size = task.metadata?.size;
    final name = task.metadata?.name;
    final fileEntry = ModelFileEntry(
      id: ref.id,
      createdAt: now,
      createdBy: createdBy,
      storagePath: storagePath,
      size: size,
      name: name,
      downloadUrl: downloadUrl,
      falsePath: falsePath,
    );
    await databaseService.createModel(fileEntry, ref);
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
