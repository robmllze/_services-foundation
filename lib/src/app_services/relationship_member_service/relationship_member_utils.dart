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

final class RelationshipMemberUtils {
  //
  //
  //

  RelationshipMemberUtils._();

  //
  //
  //

  // static UserPubService? getUserPubServiceForRelationship({
  //   required Iterable<(String, UserPubService)>? userPubServicePool,
  //   required String userPid,
  // }) {
  //   return userPubServicePool?.firstWhereOrNull((e) => e.$1 == userPid)?.$2;
  // }

  //
  //
  //

  /// Gets the IDs of all relationships containing a [memberId] from a [relationshipPool].
  static Iterable<String> getRelationshipIdsForMember(
    Iterable<ModelRelationship>? relationshipPool,
    String? memberId,
  ) {
    return RelationshipMemberUtils.getRelationshipsForMember(
      relationshipPool: relationshipPool,
      memberId: memberId,
    ).map((e) => e.id).nonNulls;
  }

  //
  //
  //

  /// Gets all relationships containing a [memberId] from a [relationshipPool].
  static Iterable<ModelRelationship> getRelationshipsForMember({
    required Iterable<ModelRelationship>? relationshipPool,
    required String? memberId,
  }) {
    return memberId != null
        ? relationshipPool?.where((e) {
              return e.memberPids?.contains(memberId) == true;
            }).toSet() ??
            {}
        : {};
  }

  //
  //
  //

  /// Extracts the member IDs from a relationship that are public user IDs.
  Set<String> extractUserMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.memberPids?.where((e) {
          return IdUtils.getPrefix(e) == IdUtils.USER_PID_PREFIX;
        }).toSet() ??
        {};
  }

  //
  //
  //

  /// Extracts the member IDs from a relationship that are public organization IDs.
  Set<String> extractOrganizationMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.memberPids?.where((e) {
          return IdUtils.getPrefix(e) == IdUtils.ORGANIZATION_PID_PPREFIX;
        }).toSet() ??
        {};
  }
}
