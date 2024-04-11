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

  static Set<String> extractUserMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.USER_PID_PREFIX,
      },
    );
  }

  static Set<String> extractOrganizationMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.ORGANIZATION_PID_PPREFIX,
      },
    );
  }

  static Set<String> extractProjectMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.PROJECT_PID_PPREFIX,
      },
    );
  }

  static Set<String> extractJobMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.JOB_PID_PPREFIX,
      },
    );
  }

  static Set<String> extractMemberPidsFromRelationships({
    required Iterable<ModelRelationship> relationshipPool,
    required Iterable<String> memberPidPrefixes,
  }) {
    final result = <String>{};
    for (final relationship in relationshipPool) {
      final chunk = relationship.extractMemberPids(
        memberPidPrefixes: memberPidPrefixes,
      );
      result.addAll(chunk);
    }
    return result;
  }

  static Map<String, ModelRelationship> generateMemberPidRelationshipMap({
    required Iterable<ModelRelationship> relationshipPool,
  }) {
    final entries = relationshipPool.expand(
      (a) => a.memberPids?.map((b) => MapEntry(b, a)) ?? <MapEntry<String, ModelRelationship>>{},
    );
    final result = Map.fromEntries(entries);
    return result;
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
    required String relationshipId,
    required String senderPid,
    required String receiverPid,
    required DateTime dateSent,
    required Model? def,
    required RelationshipDefType? defType,
  }) {
    final relationshipModel = ModelRelationship(
      id: relationshipId,
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
      relationshipId: relationshipId,
    );
    return BatchWriteOperation<ModelRelationship>(
      relationshipRef,
      model: relationshipModel,
    );
  }
}
