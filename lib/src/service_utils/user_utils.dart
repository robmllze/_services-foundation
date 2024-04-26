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
    final pidSeed = userId; // IdUtility.generateUuidV4C();
    final userPid = IdUtility(seed: pidSeed).idToUserPid(userId: userId);
    final user = ModelUser(
      id: userId,
      pid: userPid,
      pidSeed: pidSeed,
      createdAt: now,
    );
    final userPub = ModelUserPub(
      id: userPid,
      userId: userId,
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
