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

final class ProjectUtils {
  //
  //
  //

  static Iterable<ModelProjectPub> filterProjectPubsByRelationship({
    required String? relationshipId,
    required Iterable<ModelRelationship>? relationshipPool,
    required Iterable<ModelProjectPub>? projectPubPool,
  }) {
    final relationship = ModelRelationship.fromPool(pool: relationshipPool, id: relationshipId);
    if (relationship != null) {
      final pids = RelationshipUtils.extractProjectMemberPids(relationship: relationship);
      final result =
          pids.map((pid) => ModelProjectPub.fromPool(pool: projectPubPool, id: pid)).nonNulls;
      return result;
    } else {
      return [];
    }
  }
}
