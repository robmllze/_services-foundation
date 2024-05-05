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

final class UserUtils {
  //
  //
  //

  UserUtils._();

  //
  //
  //

  @visibleForTesting
  static ({
    Future<void> future,
    ModelUser user,
    ModelUserPub userPub,
  }) dbNewUser({
    required ServiceEnvironment serviceEnvironment,
    required String displayName,
    required String email,
    required String userId,
  }) {
    final now = DateTime.now();
    final userId = serviceEnvironment.authServiceBroker.pCurrentUser.value!.userId;
    final seed = IdUtils.newUuidV4();
    final userPid = IdUtils.idToUserPid(seed: seed, userId: userId);
    final user = ModelUser(
      createdAt: now,
      id: userId,
      pid: userPid,
      seed: seed,
    );
    final userPub = ModelUserPub(
      createdAt: now,
      id: userPid,
      displayName: displayName,
      displayNameSearchable: displayName,
      email: email,
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(
        ref: Schema.usersRef(userId: userId),
        model: user,
      ),
      CreateOperation(
        ref: Schema.userPubsRef(userPid: userPid),
        model: userPub,
      ),
    ]);
    return (
      future: future,
      user: user,
      userPub: userPub,
    );
  }

  //
  //
  //

  static Future<void> dbDeleteUser({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
    required String userPid,
    required Iterable<ModelRelationship> relationshipPool,
    required Iterable<ModelJob>? jobPool,
    required Iterable<ModelJobPub> jobPubPool,
    required Iterable<ModelOrganization>? organizationPool,
    required Iterable<ModelOrganizationPub> organizationPubPool,
    required Iterable<ModelProject> ? projectPool,
    required Iterable<ModelProjectPub> projectPubPool,
  }) async {
    // ----

    final relationshipIds =
        relationshipPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final relationships0 = relationshipIds.map(
      (id) => DeleteOperation(
        ref: Schema.relationshipsRef(relationshipId: id),
      ),
    );

    final organizationIds =
        organizationPool?.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final organizations0 = organizationIds?.map(
      (id) => DeleteOperation(
        ref: Schema.organizationsRef(organizationId: id),
      ),
    );

    final organizationPubIds =
        organizationPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final organizationPubs0 = organizationPubIds.map(
      (id) => DeleteOperation(
        ref: Schema.organizationPubsRef(organizationPid: id),
      ),
    );

    final projectIds = projectPool?.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final projects0 = projectIds?.map(
      (id) => DeleteOperation(
        ref: Schema.projectsRef(projectId: id),
      ),
    );

    final projectPubIds =
        projectPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final projectPubs0 = projectPubIds.map(
      (id) => DeleteOperation(
        ref: Schema.projectPubsRef(projectPid: id),
      ),
    );

    final jobIds = jobPool?.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final jobs0 = jobIds?.map(
      (id) => DeleteOperation(
        ref: Schema.jobsRef(jobId: id),
      ),
    );

    final jobPubIds = jobPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    final jobPubs0 = jobPubIds.map(
      (id) => DeleteOperation(
        ref: Schema.jobPubsRef(jobPid: id),
      ),
    );

    // ----

    // Get all relationships not created by the user but where the user is a member.

    final relationships1 = relationshipPool
        .where((e) => !relationshipIds.contains(e.id))
        .map((e) => e.id)
        .nonNulls
        .map(
          (id) => RelationshipUtils.getLazyRemoveMembersOperation(
            serviceEnvironment: serviceEnvironment,
            relationshipId: id,
            memberPids: {userPid},
          ),
        );

    // ----

    final events0 = (await Future.wait(
          relationshipIds.map(
            (id) => serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
              collectionRef: Schema.relationshipEventsRef(relationshipId: id),
            ),
          ),
        ))
            .tryReduce((a, b) => [...a, ...b]) ??
        [];

    // ----

    // Deletes the user document.
    final deleteUserOperation = DeleteOperation(
      ref: Schema.usersRef(userId: userId),
    );
    // Deletes the user pub document.
    final deleteUserPubOperation = DeleteOperation(
      ref: Schema.userPubsRef(userPid: userPid),
    );

    await serviceEnvironment.databaseServiceBroker.runBatchOperations([
      ...relationships0,
      ...?organizations0,
      ...organizationPubs0,
      ...?projects0,
      ...projectPubs0,
      ...?jobs0,
      ...jobPubs0,
      ...relationships1,
      ...events0,
      deleteUserOperation,
      deleteUserPubOperation,
    ]);
  }
}
