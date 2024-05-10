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

  static Future<void> dbNewRelationship({
    required ServiceEnvironment serviceEnvironment,
    required String createdBy,
    DateTime? createdAt,
    GenericModel? def,
    RelationshipDefType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) async {
    final relationship = newRelationship(
      newRelationshipId: newRelationshipId,
      createdBy: createdBy,
      createdAt: createdAt,
      memberPids: memberPids,
      defType: defType,
      def: def,
    );
    final ref = Schema.relationshipsRef(
      relationshipId: relationship.id!,
    );
    await serviceEnvironment.databaseServiceBroker.setModel(
      relationship,
      ref,
    );
  }

  //
  //
  //

  static CreateOperation getCreateRelationshipOperation({
    required String createdBy,
    DateTime? createdAt,
    GenericModel? def,
    RelationshipDefType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) {
    final relationship = newRelationship(
      newRelationshipId: newRelationshipId,
      createdBy: createdBy,
      createdAt: createdAt,
      memberPids: memberPids,
      defType: defType,
      def: def,
    );
    final ref = Schema.relationshipsRef(
      relationshipId: relationship.id!,
    );
    return CreateOperation(
      ref: ref,
      model: relationship,
    );
  }

  //
  //
  //

  static ModelRelationship newRelationship({
    required String createdBy,
    DateTime? createdAt,
    GenericModel? def,
    RelationshipDefType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) {
    return ModelRelationship(
      id: newRelationshipId ?? IdUtils.newRelationshipId(),
      createdAt: createdAt ?? DateTime.now(),
      createdBy: createdBy,
      memberPids: {...?memberPids, createdBy},
      defType: defType,
      def: def,
    );
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

  //
  //
  //

  static Set<String> extractOrganizationMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.ORGANIZATION_PID_PREFIX,
      },
    );
  }

  //
  //
  //

  static Set<String> extractProjectMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.PROJECT_PID_PREFIX,
      },
    );
  }

  //
  //
  //

  static Set<String> extractJobMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPids(
      memberPidPrefixes: {
        IdUtils.JOB_PID_PREFIX,
      },
    );
  }

  //
  //
  //

  static Set<String> extractMemberPids({
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

  //
  //
  //

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

  static Future<void> dbDisableRelationship({
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
          id: relationshipId,
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
        collectionRef: Schema.relationshipEventsRef(relationshipId: relationshipId),
      ),
      // Operations to delete the messages collection associated with the relationship document.
      ...await serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
        collectionRef: Schema.relationshipMessagesRef(relationshipId: relationshipId),
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

  //
  //
  //

  @visibleForTesting
  static UpdateOperation getLazyRemoveMembersOperation({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
    required Set<String> memberPids,
  }) {
    final ref = Schema.relationshipsRef(relationshipId: relationshipId);
    final update = GenericModel(
      data: {
        ModelRelationship.K_MEMBER_PIDS:
            serviceEnvironment.fieldValueBroker.arrayRemoveFieldValue(memberPids.toList()),
      },
    );
    return UpdateOperation(
      ref: ref,
      model: update,
    );
  }

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
      pids: memberPids,
      limit: limit ?? memberPids.length,
    );

    if (defTypes.isNotEmpty) {
      a = a.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return a;
  }
}
