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
  //   required String userPubId,
  // }) {
  //   return userPubServicePool?.firstWhereOrNull((e) => e.$1 == userPubId)?.$2;
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
              return e.memberIds?.contains(memberId) == true;
            }).toSet() ??
            {}
        : {};
  }

  //
  //
  //

  /// Extracts the member IDs from a relationship that are public user IDs.
  Set<String> extractUserMemberIds({
    required ModelRelationship relationship,
  }) {
    return relationship.memberIds?.where((e) {
          return IdUtils.getPrefix(e) == IdUtils.USER_PUB_ID_PREFIX;
        }).toSet() ??
        {};
  }

  //
  //
  //

  /// Extracts the member IDs from a relationship that are public organization IDs.
  Set<String> extractOrganizationMemberIds({
    required ModelRelationship relationship,
  }) {
    return relationship.memberIds?.where((e) {
          return IdUtils.getPrefix(e) == IdUtils.ORGANIZATION_PUB_ID_PPREFIX;
        }).toSet() ??
        {};
  }
}
