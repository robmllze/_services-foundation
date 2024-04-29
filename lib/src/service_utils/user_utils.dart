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

  static Future<(ModelUser, ModelUserPub)> dbNewUser({
    required ServiceEnvironment serviceEnvironment,
    required String displayName,
    required String email,
    required String userId,
  }) async {
    final now = DateTime.now();
    final userId = serviceEnvironment.authServiceBroker.pCurrentUser.value!.userId;
    final seedId = IdUtils.newUuidV4();
    final userPid = IdUtils.idToUserPid(seedId: seedId, userId: userId);
    final user = ModelUser(
      id: userId,
      pid: userPid,
      seedId: seedId,
      createdAt: now,
    );
    final userPub = ModelUserPub(
      id: userPid,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      emailSearchable: email.toLowerCase(),
      createdAt: now,
    );
    await serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(
        ref: Schema.usersRef(userId: userId),
        model: user,
      ),
      CreateOperation(
        ref: Schema.userPubsRef(userPid: userPid),
        model: userPub,
      ),
    ]);
    return (user, userPub);
  }

  //
  //
  //

  // Stream.
  static Stream<ModelUserPub?>? dbUserPubStream({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
  }) {
    final userPubPath = Schema.userPubsRef(userPid: userPid);
    final userPubDataStream = serviceEnvironment.databaseServiceBroker.streamModel(userPubPath);
    final userPubModelStream = userPubDataStream.map((e) {
      return e != null ? ModelUserPub.fromJson(e.toJson()) : null;
    });
    return userPubModelStream;
  }
}
