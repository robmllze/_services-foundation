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
    required Iterable<ModelFileEntry> filePool,
    required Iterable<ModelRelationship> relationshipPool,
    required Iterable<ModelJobPub> jobPubPool,
    required Iterable<ModelOrganizationPub> organizationPubPool,
    required Iterable<ModelProjectPub> projectPubPool,
  }) async {
    // Get all relationship IDs created by userPid within the relationshipPool.
    final createdByRelationshipIds =
        relationshipPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    // Create delete operations for all relationships created by userPid.
    final createdByRelationshipDeleteOperations = createdByRelationshipIds.map(
      (id) => DeleteOperation(
        ref: Schema.relationshipsRef(relationshipId: id),
      ),
    );

    // Get all relationship IDs where userPid is a member of but not the creator
    // within the relationshipPool.
    final memberOfRelationshipIds = relationshipPool
        .where(
          (e) =>
              !createdByRelationshipIds.contains(e.id) && e.memberPids?.contains(userPid) == true,
        )
        .map((e) => e.id)
        .nonNulls;

    // Create remove member operations for all relationships where userPid is a
    // member of.
    final memberOfRelationshipDeleteOperations = memberOfRelationshipIds.map(
      (id) => RelationshipUtils.getLazyRemoveMembersOperation(
        serviceEnvironment: serviceEnvironment,
        relationshipId: id,
        memberPids: {userPid},
      ),
    );

    // Get all PIDs for organization pubs created by userPid within the organizationPubPool.
    final organizationPids =
        organizationPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    // Fetch all organization IDs corresponding to the organizationPids.
    final organizationIds = (await serviceEnvironment.databaseQueryBroker
                .streamOrganizationsByPids(pids: organizationPids)
                .firstOrNull)
            ?.map((e) => e.id)
            .nonNulls ??
        [];

    // Create delete operations for all organization pubs created by userPid.
    final organizationPubDeleteOperations = organizationPids.map(
      (id) => DeleteOperation(
        ref: Schema.organizationPubsRef(organizationPid: id),
      ),
    );

    // Create delete operations for all organizations created by userPid.
    final organizationDeleteOperations = organizationIds.map(
      (id) => DeleteOperation(
        ref: Schema.organizationsRef(organizationId: id),
      ),
    );

    // Get all PIDs fpr project pubs created by userPid within the projectPubPool.
    final projectPids =
        projectPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    // Fetch all project IDs corresponding to the projectPids.
    final projectIds = (await serviceEnvironment.databaseQueryBroker
                .streamProjectsByPids(pids: projectPids)
                .firstOrNull)
            ?.map((e) => e.id)
            .nonNulls ??
        [];

    // Create delete operations for all project pubs created by userPid.
    final projectPubsDeleteOperations = projectPids.map(
      (id) => DeleteOperation(
        ref: Schema.projectPubsRef(projectPid: id),
      ),
    );

    // Create delete operations for all projects created by userPid.
    final projectDeleteOperations = projectIds.map(
      (id) => DeleteOperation(
        ref: Schema.projectsRef(projectId: id),
      ),
    );

    // Get all PIDs for jobs created by userPid within the jobPubPool.
    final jobPids = jobPubPool.where((e) => e.createdBy == userPid).map((e) => e.id).nonNulls;

    // Fetch all job IDs corresponding to the jobPids.
    final jobIds =
        (await serviceEnvironment.databaseQueryBroker.streamJobsByPids(pids: jobPids).firstOrNull)
                ?.map((e) => e.id)
                .nonNulls ??
            [];

    // Create delete operations for all job pubs created by userPid.
    final jobPubsDeleteOperations = jobPids.map(
      (id) => DeleteOperation(
        ref: Schema.jobPubsRef(jobPid: id),
      ),
    );

    // Create delete operations for all jobs created by userPid.
    final jobsDeleteOperations = jobIds.map(
      (id) => DeleteOperation(
        ref: Schema.jobsRef(jobId: id),
      ),
    );

    // Create delete operations for all events within relationships created by userPid.
    final relationshipEventDeleteOperations = (await Future.wait(
          createdByRelationshipIds.map(
            (id) => serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
              collectionRef: Schema.relationshipEventsRef(relationshipId: id),
            ),
          ),
        ))
            .tryReduce((a, b) => [...a, ...b]) ??
        [];

    // Create a delete operation for the user document.
    final deleteUserOperation = DeleteOperation(
      ref: Schema.usersRef(userId: userId),
    );

    // Create a delete operation for the user pub document.
    final deleteUserPubOperation = DeleteOperation(
      ref: Schema.userPubsRef(userPid: userPid),
    );

    // Run all operations in a batch.
    await serviceEnvironment.databaseServiceBroker.runBatchOperations([
      ...createdByRelationshipDeleteOperations,
      ...organizationDeleteOperations,
      ...organizationPubDeleteOperations,
      ...projectDeleteOperations,
      ...projectPubsDeleteOperations,
      ...jobsDeleteOperations,
      ...jobPubsDeleteOperations,
      ...memberOfRelationshipDeleteOperations,
      ...relationshipEventDeleteOperations,
      deleteUserOperation,
      deleteUserPubOperation,
    ]);

    // Get IDs for all files created by userPid within the filePool.
    final fileIds = filePool.where((e) => e.createdBy == userPid).map((e) => e.id);

    // Delete all files created by userPid.
    await Future.wait(
      fileIds.map(
        (id) {
          final ref = Schema.fileRef(fileId: id);
          return serviceEnvironment.fileServiceBroker.deleteFile(ref);
        },
      ),
    );
  }
}
