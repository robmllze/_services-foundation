//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:cloud_firestore/cloud_firestore.dart';

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
    DataModel? def,
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

    await serviceEnvironment.databaseServiceBroker.setModel(relationship);
  }

  //
  //
  //

  static CreateOperation getCreateRelationshipOperation({
    required String createdBy,
    DateTime? createdAt,
    DataModel? def,
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
    return CreateOperation(model: relationship);
  }

  //
  //
  //

  static ModelRelationship newRelationship({
    required String createdBy,
    DateTime? createdAt,
    DataModel? def,
    RelationshipDefType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) {
    final relationshipId = newRelationshipId ?? IdUtils.newRelationshipId();
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    return ModelRelationship(
      ref: relationshipRef,
      id: relationshipId,
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
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    final currentUserId = serviceEnvironment.currentUser?.id;
    assert(currentUserId != null);
    if (currentUserId != null) {
      await serviceEnvironment.databaseServiceBroker.setModel(
        ModelRelationship(
          ref: relationshipRef,
          id: relationshipId,
          whenDisabled: {
            currentUserId: DateTime.now(),
          },
        ),
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
      DeleteOperation(
        model: ModelRelationship(
          ref: Schema.relationshipsRef(relationshipId: relationshipId),
          id: relationshipId,
        ),
      ),
      // Operations to delete the events collection associated with the relationship document.
      ...await serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
        collectionRef: Schema.relationshipEventsRef(relationshipId: relationshipId),
      ),
      // Operations to delete the messages collection associated with the relationship document.
      ...await serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
        collectionRef: Schema.relationshipMessageEventsRef(relationshipId: relationshipId),
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
    (relationship.memberPids ??= {}).addAll(memberPids);
    await serviceEnvironment.databaseServiceBroker.updateModel(relationship);
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
      (relationship.memberPids ??= {}).removeAll(memberPids);
      await serviceEnvironment.databaseServiceBroker.updateModel(relationship);
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
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    final update = DataModel(
      data: {
        ModelRelationship.K_REF: relationshipRef.toJson(),
        // TODO: DO NOT USE FIREBASE FIELD VALUES!!!
        ModelRelationship.K_MEMBER_PIDS: FieldValue.arrayRemove(memberPids.toList()),
      },
    );
    return UpdateOperation(model: update);
  }
}
