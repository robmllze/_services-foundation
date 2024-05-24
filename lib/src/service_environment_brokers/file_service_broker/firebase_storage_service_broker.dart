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
  Future<(Uint8List, ModelFileEntry)?> downloadFileFromRef(DataRef ref) async {
    try {
      final fileEntry = ModelFileEntry.from(await this.databaseServiceBroker.readModel(ref));
      final data = (await this.downloadFile(fileEntry))!;
      return (data, fileEntry);
    } catch (_) {
      return null;
    }
  }

  //
  //
  //

  @override
  Future<Uint8List?> downloadFile(ModelFileEntry fileEntry) async {
    try {
      final storagePath = fileEntry.storagePath!;
      final storageRef = this.firebaseStorage.ref(storagePath);
      final data = (await storageRef.getData())!;
      return data;
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

    final storagePath = DataRef(
      collection: [
        ...definitionPath,
        currentUserPid,
        fileId,
      ],
      id: file.name,
    ).docPath;

    final storageRef = this.firebaseStorage.ref(storagePath);
    final fileRef = Schema.filesRef(fileId: fileId);
    final pendingUploadFile = _createPendingUploadFile(
      file: file,
      storagePath: storagePath,
      fileRef: fileRef,
      fileId: fileId,
      createdBy: currentUserPid,
      title: title,
      description: description,
      definitionPath: definitionPath,
    );
    final uploadedFile = () async {
      await this.databaseServiceBroker.createModel(pendingUploadFile);
      final task = await storageRef.putData(file.bytes!);
      final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
      final uploadedFile = ModelFileEntry.of(pendingUploadFile)..downloadUrl = downloadUrl;
      await this.databaseServiceBroker.updateModel(uploadedFile);
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
  }) uploadPublicFile({
    required PlatformFile file,
    required DataRef pubRef,
    required String? fileId,
  }) {
    fileId ??= IdUtils.newUuidV4();
    final createdBy = pubRef.id!;
    final storagePath = DataRef(
      collection: [
        ...FileSchema.PUBLIC_FILES,
        createdBy,
        fileId,
      ],
      id: file.name,
    ).docPath;

    final storageRef = this.firebaseStorage.ref(storagePath);
    final pendingUploadFile = _createPendingUploadFile(
      file: file,
      storagePath: storagePath,
      fileRef: DataRef(),
      fileId: fileId,
      createdBy: createdBy,
      title: null,
      description: null,
      definitionPath: FileSchema.PUBLIC_FILES,
    );
    final uploadedFile = () async {
      await this.databaseServiceBroker.setModel(
            PublicModel(
              ref: pubRef,
              fileBook: {
                fileId!: pendingUploadFile,
              },
            ),
          );
      final task = await storageRef.putData(file.bytes!);
      final downloadUrl = Uri.tryParse(await task.ref.getDownloadURL());
      final uploadedFile = ModelFileEntry.of(pendingUploadFile)..downloadUrl = downloadUrl;
      await this.databaseServiceBroker.setModel(
            PublicModel(
              ref: pubRef,
              fileBook: {
                fileId: uploadedFile,
              },
            ),
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
  Future<void> deletePublicFile({
    required DataRef pubRef,
    required String fileId,
  }) async {
    final userPub = ModelUserPub.from(await this.databaseServiceBroker.readModel(pubRef));
    final file = userPub.fileBook?[fileId];
    if (file != null) {
      final storagePath = file.storagePath!;
      final storageRef = this.firebaseStorage.ref(storagePath);
      await storageRef.delete();
      await this._deleteFileEntry(pubRef, fileId);
    }
  }

  //
  //
  //

  Future<void> _deleteFileEntry(
    DataRef pubRef,
    String fileId,
  ) async {
    final update = DataModel(
      data: {
        PublicModel.K_REF: pubRef.toJson(),
        PublicModel.K_FILE_BOOK: {
          fileId: this.fieldValueBroker.deleteFieldValue(),
        },
      },
    );
    await this.databaseServiceBroker.setModel(update);
  }

  //
  //
  //

  static ModelFileEntry _createPendingUploadFile({
    required PlatformFile file,
    required String storagePath,
    required String fileId,
    required DataRef fileRef,
    String? createdBy,
    String? title,
    String? description,
    List<String>? definitionPath,
  }) {
    final now = DateTime.now();

    final pendingUploadFile = ModelFileEntry(
      ref: fileRef,
      id: fileId,
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
