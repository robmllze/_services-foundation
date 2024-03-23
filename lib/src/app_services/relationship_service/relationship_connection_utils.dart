//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class RelationshipConnectionUtils {
  //
  //
  //

  RelationshipConnectionUtils._();

  //
  //
  //

  static UserPubService? getConnectionServiceForRelationship({
    required List<(String, UserPubService)>? connectionServicePool,
    required String userPubId,
  }) {
    final connectionService = connectionServicePool?.firstWhereOrNull((e) => e.$1 == userPubId)?.$2;
    return connectionService;
  }

  //
  //
  //

  static Iterable<String>? getRelationshipIdsForConnection(
    Iterable<ModelRelationship>? relationshipPool,
    String? connectionId,
  ) {
    if (connectionId != null) {
      if (relationshipPool != null && relationshipPool.isNotEmpty) {
        final connectionRelationships = RelationshipConnectionUtils.getRelationshipsForConnection(
          relationshipPool: relationshipPool,
          connectionId: connectionId,
        );
        if (connectionRelationships.isNotEmpty) {
          final relationshipIds = connectionRelationships.map((e) => e.id).nonNulls;
          return relationshipIds;
        }
      }
    }
    return null;
  }

  //
  //
  //

  static Iterable<ModelRelationship> getRelationshipsForConnection({
    required Iterable<ModelRelationship> relationshipPool,
    required String connectionId,
  }) {
    return relationshipPool.where((e) => e.memberIds?.contains(connectionId) == true);
  }
}
