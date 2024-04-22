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

  static Future<void> dbCreateNewUserData({
    required ServiceEnvironment serviceEnvironment,
    required String displayName,
    required String email,
    required String userId,
  }) async {
    final now = DateTime.now();
    final userPid = IdUtils.toUserPid(userId: userId);
    await serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(
        ref: Schema.usersRef(userId: userId),
        model: ModelUser(
          id: userId,
          pid: userPid,
          createdAt: now,
        ),
      ),
      CreateOperation(
        ref: Schema.userPubsRef(userPid: userPid),
        model: ModelUserPub(
          id: userPid,
          userId: userId,
          displayName: displayName,
          displayNameSearchable: displayName.toLowerCase(),
          emailSearchable: email.toLowerCase(),
          createdAt: now,
        ),
      ),
    ]);
  }

  //
  //
  //

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
