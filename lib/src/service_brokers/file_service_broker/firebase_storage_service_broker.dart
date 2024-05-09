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

  final DatabaseServiceInterface databaseServiceBroker;
  final FirebaseFieldValueBroker fieldValueBroker;
  final FirebaseStorage firebaseStorage;

  //
  //
  //

  FirebaseStorageServiceBroker({
    required this.databaseServiceBroker,
    required this.fieldValueBroker,
    required this.firebaseStorage,
  });

  //
  //
  //

  @override
  Future<(Uri, ModelFileEntry)?> downloadUrl(DataRef ref) async {
    try {
      final fileEntry = ModelFileEntry.from(await this.databaseServiceBroker.readModel(ref));
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
      final fileEntry = ModelFileEntry.from(await this.databaseServiceBroker.readModel(ref));
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
  ({
    ModelFileEntry pendingUploadFile,
    Future<ModelFileEntry> uploadedFile,
  }) uploadFile({
    required PlatformFile file,
    required String currentUserPid,
    List<String> definitionPath = FileSchema.FILES,
    String? title,
    String? description,
  }) {
    final fileId = IdUtils.newUuidV4();
    final fileRef = DataRef(
      collection: [...definitionPath, currentUserPid],
      id: file.name,
    );
    final storagePath = fileRef.docPath;
    final storageRef = this.firebaseStorage.ref(storagePath);
    final pendingUploadFile = _createPendingUploadFile(
      file: file,
      fileRef: fileRef,
      createdBy: currentUserPid,
      title: title,
      description: description,
      definitionPath: definitionPath,
    );
    final uploadedFile = () async {
      final ref = Schema.fileRef(fileId: fileId);
      await this.databaseServiceBroker.createModel(pendingUploadFile, ref);
      final task = await storageRef.putData(file.bytes!);
      final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
      final uploadedFile = ModelFileEntry.of(pendingUploadFile)..downloadUrl = downloadUrl;
      await this.databaseServiceBroker.updateModel(uploadedFile, ref);
      return uploadedFile;
    }();
    return (
      pendingUploadFile: pendingUploadFile,
      uploadedFile: uploadedFile,
    );
  }

  //
  //
  //

  @override
  ({
    ModelFileEntry pendingUploadFile,
    Future<ModelFileEntry> uploadedFile,
  }) uploadAvatar({
    required PlatformFile file,
    required String currentUserPid,
  }) {
    final fileRef = DataRef(
      collection: [...FileSchema.AVATAR_IMAGE, currentUserPid],
      id: file.name,
    );
    final storagePath = fileRef.docPath;
    final storageRef = this.firebaseStorage.ref(storagePath);
    final pendingUploadFile = _createPendingUploadFile(
      file: file,
      fileRef: fileRef,
      createdBy: currentUserPid,
      title: null,
      description: null,
      definitionPath: FileSchema.AVATAR_IMAGE,
    );
    final uploadedFile = () async {
      final ref = Schema.userPubsRef(userPid: currentUserPid);
      await this.databaseServiceBroker.updateModel(
            ModelUserPub(avatar: pendingUploadFile),
            ref,
          );
      final task = await storageRef.putData(file.bytes!);
      final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
      final uploadedFile = ModelFileEntry.of(pendingUploadFile)..downloadUrl = downloadUrl;
      await this.databaseServiceBroker.updateModel(
            ModelUserPub(avatar: uploadedFile),
            ref,
          );
      return uploadedFile;
    }();
    return (
      pendingUploadFile: pendingUploadFile,
      uploadedFile: uploadedFile,
    );
  }

  //
  //
  //

  @override
  Future<void> deleteFile(DataRef ref) async {
    final fileEntry = ModelFileEntry.from(await this.databaseServiceBroker.readModel(ref));
    final storagePath = fileEntry.storagePath!;
    final storageRef = this.firebaseStorage.ref(storagePath);
    await storageRef.delete();
    await this.databaseServiceBroker.deleteModel(ref);
  }

  //
  //
  //

  @override
  Future<void> deleteAvatar({
    required String currentUserPid,
  }) async {
    final ref = Schema.userPubsRef(userPid: currentUserPid);
    final userPub = ModelUserPub.from(await this.databaseServiceBroker.readModel(ref));
    final fileEntry = userPub.avatar;
    if (fileEntry != null) {
      final storagePath = fileEntry.storagePath!;
      final storageRef = this.firebaseStorage.ref(storagePath);
      await storageRef.delete();
    }
    await this._deleteAvatarField(currentUserPid);
  }

  //
  //
  //

  Future<void> _deleteAvatarField(
    String userPid,
  ) async {
    final userPubUpdate = GenericModel(
      data: {
        ModelUserPub.K_AVATAR: this.fieldValueBroker.deleteFieldValue(),
      },
    );
    final ref = Schema.userPubsRef(userPid: userPid);
    await this.databaseServiceBroker.updateModel(userPubUpdate, ref);
  }

  //
  //
  //

  static ModelFileEntry _createPendingUploadFile({
    required PlatformFile file,
    required DataRef fileRef,
    String? createdBy,
    String? title,
    String? description,
    List<String>? definitionPath,
  }) {
    final now = DateTime.now();
    final storagePath = fileRef.docPath;
    final pendingUploadFile = ModelFileEntry(
      id: fileRef.id!,
      createdAt: now,
      createdBy: createdBy,
      storagePath: storagePath,
      title: title,
      titleSearchable: title,
      extension: file.extension,
      description: description,
      size: file.size,
      name: file.name,
      definitionPath: definitionPath,
    );
    return pendingUploadFile;
  }
}
