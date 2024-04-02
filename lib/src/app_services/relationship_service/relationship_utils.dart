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
    Iterable<ModelRelationship> relationshipPool, {
    required Iterable<String> memberIdPrefixes,
  }) {
    final memberIds = <String>{};
    for (final relationship in relationshipPool) {
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
      final userPubId = IdUtils.toUserPubId(userId: userId);
      return serviceEnvironment.databaseQueryBroker.queryRelationshipsForMembers(
        databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
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
