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

final class UserUtils {
  //
  //
  //

  UserUtils._();

  //
  //
  //

  // --- ModelUser CRUD ---

  // Create.
  static BatchWriteOperation dbCreateUserOperation({
    required ModelUser user,
  }) {
    final ref = Schema.usersRef(userId: user.id!);
    return BatchWriteOperation(ref, mergeExisting: true);
  }

  // Read.
  static Future<ModelUser?> dbReadUser({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
  }) async {
    final ref = Schema.usersRef(userId: userId);
    final genericModel = await serviceEnvironment.databaseServiceBroker.getModel(ref);
    if (genericModel != null) {
      return ModelUser.from(genericModel);
    }
    return null;
  }

  // Update.
  static BatchWriteOperation dbUpdateUserOperation({
    required ModelUser user,
  }) {
    final ref = Schema.usersRef(userId: user.id!);
    return BatchWriteOperation(
      ref,
      mergeExisting: false,
      overwriteExisting: false,
    );
  }

  // Delete.
  static BatchWriteOperation dbDeleteUserOperation({
    required String userId,
  }) {
    final ref = Schema.usersRef(userId: userId);
    return BatchWriteOperation(ref, delete: true);
  }

  //
  //
  //

  // --- ModelUserPub CRUD ---

  // Create.
  static BatchWriteOperation dbCreateUserPubOperation({
    required ModelUserPub userPub,
  }) {
    final ref = Schema.userPubsRef(userPid: userPub.id!);
    return BatchWriteOperation(
      ref,
      mergeExisting: false,
      overwriteExisting: false,
    );
  }

  // Read.
  static Future<ModelUserPub?> dbReadUserPub({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
  }) async {
    final ref = Schema.userPubsRef(userPid: userPid);
    final genericModel = await serviceEnvironment.databaseServiceBroker.getModel(ref);
    if (genericModel != null) {
      return ModelUserPub.from(genericModel);
    }
    return null;
  }

  // Update.
  static BatchWriteOperation dbUpdateUserPubOperation({
    required ModelUserPub userPub,
  }) {
    final ref = Schema.userPubsRef(userPid: userPub.id!);
    return BatchWriteOperation(
      ref,
      mergeExisting: false,
      overwriteExisting: false,
    );
  }

  // Delete.
  static BatchWriteOperation dbDeleteUserPubOperation({
    required String userPid,
  }) {
    final ref = Schema.userPubsRef(userPid: userPid);
    return BatchWriteOperation(ref, delete: true);
  }

  // Stream.
  static Stream<ModelUserPub?>? dbUserPubStream(
    ServiceEnvironment serviceEnvironment, {
    String? userPid,
  }) {
    userPid = userPid ?? serviceEnvironment.authServiceBroker.pCurrentUser.value?.userPid;
    assert(userPid != null);
    if (userPid != null) {
      final userPubPath = Schema.userPubsRef(userPid: userPid);
      final userPubDataStream = serviceEnvironment.databaseServiceBroker.streamModel(userPubPath);
      final userPubModelStream = userPubDataStream.map((e) {
        return e != null ? ModelUserPub.fromJson(e.toJson()) : null;
      });
      return userPubModelStream;
    }
    return null;
  }
}
