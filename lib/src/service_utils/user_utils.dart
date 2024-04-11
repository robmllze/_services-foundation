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

  static Stream<ModelUserPub?>? userPubStream(
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
