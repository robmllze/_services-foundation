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

  static UserPubService? getUserPubServiceForRelationship({
    required List<(String, UserPubService)>? userPubServicePool,
    required String userPubId,
  }) {
    final userPubService = userPubServicePool?.firstWhereOrNull((e) => e.$1 == userPubId)?.$2;
    return userPubService;
  }

  //
  //
  //

  static Iterable<String>? getRelationshipIdsForMember(
    Iterable<ModelRelationship>? relationshipPool,
    String? memberId,
  ) {
    if (memberId != null) {
      if (relationshipPool != null && relationshipPool.isNotEmpty) {
        final memberRelationships = RelationshipMemberUtils.getRelationshipsForMember(
          relationshipPool: relationshipPool,
          memberId: memberId,
        );
        if (memberRelationships.isNotEmpty) {
          final relationshipIds = memberRelationships.map((e) => e.id).nonNulls;
          return relationshipIds;
        }
      }
    }
    return null;
  }

  //
  //
  //

  static Iterable<ModelRelationship> getRelationshipsForMember({
    required Iterable<ModelRelationship> relationshipPool,
    required String memberId,
  }) {
    return relationshipPool.where((e) => e.memberIds?.contains(memberId) == true);
  }
}
