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

final class RelationshipUtils {
  //
  //
  //

  RelationshipUtils._();

  //
  //
  //

  static Iterable<ModelRelationship> filterByDefType({
    required Iterable<ModelRelationship>? relationshipPool,
    required Set<RelationshipDefType>? defTypes,
  }) {
    if (defTypes == null || defTypes.isEmpty) return [];
    return relationshipPool?.where(
          (rel) {
            final defType = rel.defType;
            return defType != null ? defTypes.contains(defType) : false;
          },
        ) ??
        [];
  }

  //
  //
  //

  static Iterable<ModelRelationship> filterByEveryMember({
    required Iterable<ModelRelationship>? relationshipPool,
    required Set<String?>? memberPids,
  }) {
    final pids = memberPids?.nonNulls;
    if (pids == null || pids.isEmpty) return [];
    return relationshipPool?.where(
          (rel) {
            return pids.every((pid) {
              return rel.memberPids?.contains(pid) == true;
            });
          },
        ) ??
        [];
  }

  //
  //
  //

  static Iterable<ModelRelationship> filterByAnyMember({
    required Iterable<ModelRelationship>? relationshipPool,
    required Set<String>? memberPids,
  }) {
    final pids = memberPids?.nonNulls;
    if (pids == null || pids.isEmpty) return [];
    return relationshipPool?.where(
          (rel) {
            return pids.any((pid) {
              return rel.memberPids?.contains(pid) == true;
            });
          },
        ) ??
        [];
  }

  //
  //
  //

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

  //
  //
  //

  static Set<String> extractMemberPidsFromRelationships(
    Iterable<ModelRelationship> relationshipPool, {
    required Iterable<String> memberPidPrefixes,
  }) {
    final memberPids = <String>{};
    for (final relationship in relationshipPool) {
      Iterable<String>? temp = relationship.memberPids;
      if (temp != null && temp.isNotEmpty) {
        temp = temp.where((e) => memberPidPrefixes.any((prefix) => e.startsWith(prefix)));
        memberPids.addAll(temp);
      }
    }
    return memberPids;
  }

  //
  //
  //

  static Future<void> disableRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    final relationshipPath = Schema.relationshipsRef(
      relationshipId: relationshipId,
    );
    final currentUserId = serviceEnvironment.currentUser?.userId;
    assert(currentUserId != null);
    if (currentUserId != null) {
      await serviceEnvironment.databaseServiceBroker.setModel(
        ModelRelationship(
          whenDisabled: {
            currentUserId: DateTime.now(),
          },
        ),
        relationshipPath,
      );
    }
  }

  //
  //
  //

  static Future<void> deleteRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    final relationshipRef = Schema.relationshipsRef(
      relationshipId: relationshipId,
    );
    await serviceEnvironment.databaseServiceBroker.deleteModel(relationshipRef);
    await lazyDeleteRelationshipEventsCollection(
      serviceEnvironment: serviceEnvironment,
      relationshipId: relationshipId,
    );
  }

  //
  //
  //

  @visibleForTesting
  static Future<void> lazyDeleteRelationshipEventsCollection({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    final collectionRef = Schema.relationshipEventsRef(relationshipId: relationshipId);
    // ignore: invalid_use_of_visible_for_testing_member
    await serviceEnvironment.databaseQueryBroker.lazyDeleteCollection(
      databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
      collectionRef: collectionRef,
    );
  }

  //
  //
  //

  static Future<ModelRelationship?> getRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    final genericModel = await serviceEnvironment.databaseServiceBroker.getModel(
      Schema.relationshipsRef(relationshipId: relationshipId),
    );

    if (genericModel != null) {
      final relationshipModel = ModelRelationship.from(genericModel);
      return relationshipModel;
    }
    return null;
  }

  //
  //
  //

  static Stream<Iterable<ModelRelationship>>? relationshipsStream(
    ServiceEnvironment serviceEnvironment, {
    String? userId,
  }) {
    userId = userId ?? serviceEnvironment.authServiceBroker.pCurrentUser.value?.userId;
    assert(userId != null);
    if (userId != null) {
      final userPid = IdUtils.toUserPid(userId: userId);
      return serviceEnvironment.databaseQueryBroker.queryRelationshipsForMembers(
        databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
        memberPids: {userPid},
      );
    }
    return null;
  }

  //
  //
  //

  static Future<void> createRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
    required DateTime dateSent,
    required Model? def,
    required RelationshipDefType? defType,
  }) async {
    final relationshipModel = ModelRelationship(
      id: newRelationshipId,
      memberPids: {senderPid, receiverPid},
      def: def?.toGenericModel(),
      defType: defType,
      whenEnabled: {
        senderPid: dateSent,
        receiverPid: dateSent,
      },
    );
    final relationshipRef = Schema.relationshipsRef(
      relationshipId: newRelationshipId,
    );
    await serviceEnvironment.databaseServiceBroker.setModel(
      relationshipModel,
      relationshipRef,
    );
  }

  //
  //
  //

  static BatchWriteOperation<ModelRelationship> getCreateRelationshipOperation({
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
    required DateTime dateSent,
    required Model? def,
    required RelationshipDefType? defType,
  }) {
    final relationshipModel = ModelRelationship(
      id: newRelationshipId,
      def: def?.toGenericModel(),
      defType: defType,
      memberPids: {
        senderPid,
        receiverPid,
      },
      whenEnabled: {
        receiverPid: dateSent,
        senderPid: dateSent,
      },
    );

    final relationshipRef = Schema.relationshipsRef(
      relationshipId: newRelationshipId,
    );
    return BatchWriteOperation<ModelRelationship>(
      relationshipRef,
      model: relationshipModel,
    );
  }
}
