//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class UserPubUtils {
  //
  //
  //

  UserPubUtils._();

  //
  //
  //

  static Stream<ModelUserPub?>? userPubStream(
    ServiceEnvironment serviceEnvironment, {
    String? userPubId,
  }) {
    userPubId = userPubId ?? serviceEnvironment.authServiceBroker.pCurrentUser.value?.userPubId;
    assert(userPubId != null);
    if (userPubId != null) {
      final userPubPath = Schema.userPubsRef(userPubId: userPubId);
      final userPubDataStream = serviceEnvironment.databaseServiceBroker.streamModel(userPubPath);
      final userPubModelStream = userPubDataStream.map((e) {
        return e != null ? ModelUserPub.fromJson(e.toJson()) : null;
      });
      return userPubModelStream;
    }
    return null;
  }
}
