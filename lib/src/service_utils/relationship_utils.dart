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

  // --- ModelRelationship CRUD ---

  // Create.
  static BatchWriteOperation<ModelRelationship> dbCreateRelationshipOperation({
    required ModelRelationship relationship,
  }) {
    final ref = Schema.relationshipsRef(relationshipId: relationship.id!);
    return BatchWriteOperation(ref, model: relationship, mergeExisting: true);
  }

  // Read.
  static Future<ModelRelationship?> dbReadRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    final ref = Schema.relationshipsRef(relationshipId: relationshipId);
    final genericModel = await serviceEnvironment.databaseServiceBroker.getModel(ref);
    if (genericModel != null) {
      return ModelRelationship.from(genericModel);
    }
    return null;
  }

  // Update.
  static BatchWriteOperation<ModelRelationship> dbUpdateRelationshipOperation({
    required ModelRelationship relationship,
  }) {
    final ref = Schema.relationshipsRef(relationshipId: relationship.id!);
    return BatchWriteOperation(
      ref,
      model: relationship,
      mergeExisting: false,
      overwriteExisting: false,
    );
  }

  // Delete.
  static BatchWriteOperation<ModelRelationship> dbDeleteRelationshipOperation({
    required String relationshipId,
  }) {
    final ref = Schema.relationshipsRef(relationshipId: relationshipId);
    return BatchWriteOperation(ref, delete: true);
  }

  //
  //
  //

  static Stream<Iterable<ModelRelationship>> dbQueryRelationshipsForAnyMembers({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> memberPids,
    Set<RelationshipDefType> defTypes = const {},
    int limit = 100,
  }) {
    var a = serviceEnvironment.databaseQueryBroker.queryRelationshipsForAnyMembers(
      databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
      memberPids: memberPids,
      limit: limit,
    );

    if (defTypes.isNotEmpty) {
      a = a.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return a;
  }

  //
  //
  //

  static Stream<Iterable<ModelRelationship>> dbQueryRelationshipsForAllMembers({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> memberPids,
    Set<RelationshipDefType> defTypes = const {},
    int limit = 100,
  }) {
    var a = serviceEnvironment.databaseQueryBroker.queryRelationshipsForAllMembers(
      databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
      memberPids: memberPids,
      limit: limit,
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

  @visibleForTesting
  static Future<Iterable<BatchWriteOperation>> getLazyDeleteRelationshipOperations({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    return [
      // Operation to delete the relationship document.
      dbDeleteRelationshipOperation(relationshipId: relationshipId),
      // Operations to delete the events collection associated with the relationship document.
      // ignore: invalid_use_of_visible_for_testing_member
      ...await serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
        databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
        collectionRef: Schema.relationshipEventsRef(relationshipId: relationshipId),
      ),
    ];
  }

  //
  //
  //

  static Future<void> addMembers({
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

  static Future<void> removeMembers({
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

  static Future<void> writeNewRelationship({
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

  //
  //
  //

  static ModelRelationship createNewRelationship({
    required Set<String> memberPids,
    required RelationshipDefType defType,
    GenericModel? def,
  }) {
    return ModelRelationship(
      id: IdUtils.newId(),
      defType: defType,
      def: def,
      memberPids: memberPids,
      createdAt: DateTime.now(),
    );
  }
}
