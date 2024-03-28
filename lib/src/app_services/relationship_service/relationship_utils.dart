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

  static Set<String> extractMemberIdsFromRelationships(
    Iterable<ModelRelationship> relationshipModels, {
    required Iterable<String> memberIdPrefixes,
  }) {
    final memberIds = <String>{};
    for (final relationship in relationshipModels) {
      Iterable<String>? temp = relationship.memberIds;
      if (temp != null && temp.isNotEmpty) {
        temp = temp.where((e) => memberIdPrefixes.any((prefix) => e.startsWith(prefix)));
        memberIds.addAll(temp);
      }
    }
    return memberIds;
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
    // ignore: invalid_use_of_visible_for_testing_member
    await deleteRelationshipEventsCollection(
      serviceEnvironment: serviceEnvironment,
      relationshipId: relationshipId,
    );
  }

  //
  //
  //

  // TODO: Replace this method with one that deletes the collection via a backend function.
  @visibleForTesting
  static Future<void> deleteRelationshipEventsCollection({
    required ServiceEnvironment serviceEnvironment,
    required String relationshipId,
  }) async {
    // await serviceEnvironment.functionsServiceBroker
    //     .deleteCollection(relationshipEventsCollectionPath);
    final collectionRef = Schema.relationshipEventsRef(relationshipId: relationshipId);
    await serviceEnvironment.databaseQueryBroker.deleteCollectionTest(
      databaseService: serviceEnvironment.databaseServiceBroker,
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
      final userPubId = IdUtils.toUserPubId(userId: userId);
      return serviceEnvironment.databaseQueryBroker.queryRelationshipsForMembers(
        databaseService: serviceEnvironment.databaseServiceBroker,
        memberIds: {userPubId},
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
    required String senderPubId,
    required String receiverPubId,
    required DateTime dateSent,
    required Model? def,
    required RelationshipDefType? defType,
  }) async {
    final relationshipModel = ModelRelationship(
      id: newRelationshipId,
      memberIds: {senderPubId, receiverPubId},
      def: def?.toGenericModel(),
      defType: defType,
      whenEnabled: {
        senderPubId: dateSent,
        receiverPubId: dateSent,
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
    required String senderPubId,
    required String receiverPubId,
    required DateTime dateSent,
    required Model? def,
    required RelationshipDefType? defType,
  }) {
    final relationshipModel = ModelRelationship(
      id: newRelationshipId,
      def: def?.toGenericModel(),
      defType: defType,
      memberIds: {
        senderPubId,
        receiverPubId,
      },
      whenEnabled: {
        receiverPubId: dateSent,
        senderPubId: dateSent,
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
