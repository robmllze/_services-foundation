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

  static Stream<Iterable<ModelRelationship>> dbStreamRelationshipsForAnyMembers({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> memberPids,
    Set<RelationshipDefType> defTypes = const {},
    int? limit,
  }) {
    var a = serviceEnvironment.databaseQueryBroker.streamRelationshipsForAnyMembers(
      databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
      pids: memberPids,
      limit: limit ?? memberPids.length,
    );

    if (defTypes.isNotEmpty) {
      a = a.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return a;
  }

  //
  //
  //

  static Stream<Iterable<ModelRelationship>> dbStreamRelationshipsForAllMembers({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> memberPids,
    Set<RelationshipDefType> defTypes = const {},
    int? limit,
  }) {
    var a = serviceEnvironment.databaseQueryBroker.streamRelationshipsForAnyMembers(
      databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
      pids: memberPids,
      limit: limit ?? memberPids.length,
    );

    if (defTypes.isNotEmpty) {
      a = a.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return a;
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
      await serviceEnvironment.databaseServiceBroker.createOrUpdateModel(
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

  @visibleForTesting
  static Future<Iterable<BatchOperation>> getLazyDeleteRelationshipOperations({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    return [
      // Operation to delete the relationship document.
      DeleteOperation(ref: Schema.relationshipsRef(relationshipId: relationshipId)),
      // Operations to delete the events collection associated with the relationship document.
      ...await serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
        databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
        collectionRef: Schema.relationshipEventsRef(relationshipId: relationshipId),
      ),
    ];
  }

  //
  //
  //

  static Future<void> dbAddMembers({
    required ServiceEnvironment serviceEnvironment,
    required ModelRelationship relationship,
    required Set<String> memberPids,
  }) async {
    final relationshipId = relationship.id;
    if (relationshipId != null) {
      final ref = Schema.relationshipsRef(relationshipId: relationshipId);
      (relationship.memberPids ??= {}).addAll(memberPids);
      await serviceEnvironment.databaseServiceBroker.updateModel(
        relationship,
        ref,
      );
    }
  }

  //
  //
  //

  static Future<void> dbRemoveMembers({
    required ServiceEnvironment serviceEnvironment,
    required ModelRelationship relationship,
    required Set<String> memberPids,
  }) async {
    final relationshipId = relationship.id;
    if (relationshipId != null) {
      final ref = Schema.relationshipsRef(relationshipId: relationshipId);
      (relationship.memberPids ??= {}).removeAll(memberPids);
      await serviceEnvironment.databaseServiceBroker.updateModel(
        relationship,
        ref,
      );
    }
  }

  static Future<void> dbCreateNewRelationship({
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
    await serviceEnvironment.databaseServiceBroker.createOrUpdateModel(
      relationshipModel,
      relationshipRef,
    );
  }

  //
  //
  //

  static ModelRelationship createNewRelationship({
    required String userPid,
    required Set<String> memberPids,
    required RelationshipDefType defType,
    GenericModel? def,
  }) {
    final relationshipId = IdUtils.newRelationshipId();
    final now = DateTime.now();
    return ModelRelationship(
      whenCreated: {userPid: now},
      id: relationshipId,
      defType: defType,
      def: def,
      memberPids: memberPids,
    );
  }

  //
  //
  //

  static CreateOperation getCreateRelationshipOperation({
    required String relationshipId,
    required String senderPid,
    required String receiverPid,
    required DateTime sentAt,
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
        receiverPid: sentAt,
        senderPid: sentAt,
      },
    );

    return CreateOperation(
      ref: Schema.relationshipsRef(relationshipId: relationshipId),
      model: relationshipModel,
    );
  }
}
