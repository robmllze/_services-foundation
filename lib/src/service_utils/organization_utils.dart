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

final class OrganizationUtils {
  //
  //
  //

  OrganizationUtils._();

  //
  //
  //

  static Iterable<ModelOrganizationPub> getOrganizationPubsForRelationship({
    required String? relationshipId,
    required Iterable<ModelRelationship>? relationshipPool,
    required Iterable<ModelOrganizationPub>? organizationPubPool,
  }) {
    final relationship = ModelRelationship.fromPool(pool: relationshipPool, id: relationshipId);
    if (relationship != null) {
      final organizationPids =
          RelationshipUtils.extractOrganizationMemberPids(relationship: relationship);
      final organizationPubs = organizationPids
          .map((pid) => ModelOrganizationPub.fromPool(pool: organizationPubPool, id: pid))
          .nonNulls;
      return organizationPubs;
    } else {
      return [];
    }
  }
}
