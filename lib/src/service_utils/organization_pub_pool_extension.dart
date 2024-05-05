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

extension OrganizationPubPoolExtension on Iterable<ModelOrganizationPub> {
  //
  //
  //

  Iterable<ModelOrganizationPub> filterByRelationship({
    required String? relationshipId,
    required Iterable<ModelRelationship>? relationshipPool,
  }) {
    final relationship = relationshipPool?.firstWhereOrNull((e) => e.id == relationshipId);
    if (relationship != null) {
      final pids = RelationshipUtils.extractOrganizationMemberPids(relationship: relationship);
      final result = pids.map((pid) => this.firstWhereOrNull((e) => e.id == pid)).nonNulls;
      return result;
    } else {
      return [];
    }
  }
}
