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
  static (
    Future<void>,
    ModelUser,
    ModelUserPub,
  ) dbNewUser({
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
      id: userId,
      pid: userPid,
      seed: seed,
      createdAt: now,
    );
    final userPub = ModelUserPub(
      id: userPid,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      emailSearchable: email.toLowerCase(),
      createdAt: now,
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
      future,
      user,
      userPub,
    );
  }
}
