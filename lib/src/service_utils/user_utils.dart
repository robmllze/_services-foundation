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

  @visibleForTesting
  static ({
    Future<void> future,
    ModelUser user,
    ModelUserPub userPub,
  }) dbNewUser({
    required ServiceEnvironment serviceEnvironment,
    required String displayName,
    required String email,
    required String userId,
  }) {
    final now = DateTime.now();
    final userId = serviceEnvironment.authServiceBroker.pCurrentUser.value!.userId;
    final seed = IdUtils.newUuidV4();
    final userPid = IdUtils.idToUserPid(seed: seed, userId: userId);
    final user = ModelUser(
      createdAt: now,
      id: userId,
      pid: userPid,
      seed: seed,
    );
    final userPub = ModelUserPub(
      createdAt: now,
      id: userPid,
      displayName: displayName,
      displayNameSearchable: displayName,
      email: email,
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(
        ref: Schema.usersRef(userId: userId),
        model: user,
      ),
      CreateOperation(
        ref: Schema.userPubsRef(userPid: userPid),
        model: userPub,
      ),
    ]);
    return (
      future: future,
      user: user,
      userPub: userPub,
    );
  }
}
