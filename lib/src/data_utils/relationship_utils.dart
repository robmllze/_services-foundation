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
    Model? def,
    RelationshipType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) async {
    final relationship = newRelationship(
      newRelationshipId: newRelationshipId,
      createdBy: createdBy,
      createdAt: createdAt,
      memberPids: memberPids,
      type: defType,
      content: def,
    );

    await serviceEnvironment.databaseServiceBroker.createModel(relationship);
  }

  //
  //
  //

  static CreateOperation getCreateRelationshipOperation({
    required String createdBy,
    DateTime? createdAt,
    Model? def,
    RelationshipType? defType,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) {
    final relationship = newRelationship(
      newRelationshipId: newRelationshipId,
      createdBy: createdBy,
      createdAt: createdAt,
      memberPids: memberPids,
      type: defType,
      content: def,
    );
    return CreateOperation(model: relationship);
  }

  //
  //
  //

  static ModelRelationship newRelationship({
    required String createdBy,
    DateTime? createdAt,
    Model? content,
    RelationshipType? type,
    String? newRelationshipId,
    Set<String>? memberPids,
  }) {
    final relationshipId = newRelationshipId ?? IdUtils.newRelationshipId();
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    return ModelRelationship(
      ref: relationshipRef,
      id: relationshipId,
      createdGReg: ModelRegistration(
        registeredBy: createdBy,
        registeredAt: createdAt ?? DateTime.now(),
      ),
      memberPids: {...?memberPids, createdBy},
      type: type,
      content: content,
    );
  }

  //
  //
  //

  static Set<String> extractUserMemberPids({
    required ModelRelationship relationship,
  }) {
    return relationship.extractMemberPidsByPrefixes(
      {
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
    return relationship.extractMemberPidsByPrefixes(
      {
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
    return relationship.extractMemberPidsByPrefixes(
      {
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
    return relationship.extractMemberPidsByPrefixes(
      {
        IdUtils.JOB_PID_PREFIX,
      },
    );
  }

  //
  //
  //

  static Set<String> extractMemberPidsByPrefixes({
    required Iterable<ModelRelationship> relationshipPool,
    required Iterable<String> memberPidPrefixes,
  }) {
    final result = <String>{};
    for (final relationship in relationshipPool) {
      final chunk = relationship.extractMemberPidsByPrefixes(
        memberPidPrefixes,
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
    final update = relationship.copyWith(
      ModelRelationship(
        memberPids: {
          ...?relationship.memberPids,
          ...memberPids,
        },
      ),
    );
    await serviceEnvironment.databaseServiceBroker.updateModel(update);
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
      final update = relationship.copyWith(
        ModelRelationship(
          memberPids: {
            ...?relationship.memberPids?.where((e) => !memberPids.contains(e)),
          },
        ),
      );

      await serviceEnvironment.databaseServiceBroker.updateModel(update);
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
    final update = Model(
      {
        ModelRelationshipFields.ref.name: relationshipRef.toJson(),
        // TODO: DO NOT USE FIREBASE FIELD VALUES!!!
        ModelRelationshipFields.memberPids.name: FieldValue.arrayRemove(memberPids.toList()),
      },
    );
    return UpdateOperation(model: update);
  }
}
