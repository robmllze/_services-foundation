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

  static Iterable<ModelRelationship> getRelationshipsThatContainEveryMember({
    required Iterable<ModelRelationship>? relationshipPool,
    required Set<String>? memberPids,
  }) {
    if (memberPids == null || memberPids.isEmpty) return [];
    return relationshipPool?.where(
          (relationship) {
            return memberPids.every((pid) {
              return relationship.memberPids?.contains(pid) == true;
            });
          },
        ) ??
        [];
  }

  //
  //
  //

  static Iterable<ModelRelationship> getRelationshipsThatContainAnyMember({
    required Iterable<ModelRelationship>? relationshipPool,
    required Set<String>? memberPids,
  }) {
    if (memberPids == null || memberPids.isEmpty) return [];
    return relationshipPool?.where(
          (relationship) {
            return memberPids.any((pid) {
              return relationship.memberPids?.contains(pid) == true;
            });
          },
        ) ??
        [];
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
