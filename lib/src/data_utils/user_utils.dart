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
    final createdAt = DateTime.now();
    final userId = serviceEnvironment.authServiceBroker.pCurrentUser.value!.id!;
    final userRef = Schema.usersRef(userId: userId);
    final seed = IdUtils.newUuidV4();
    final userPid = IdUtils.idToUserPid(seed: seed, userId: userId);
    final userPubRef = Schema.userPubsRef(userPid: userPid);
    const PRIMARY_EMAIL_ID = 'primary';
    final primaryEmailRef = userPubRef + Schema.emailsRef(emailId: PRIMARY_EMAIL_ID);
    final queryableEmail = email.toQueryable();
    final user = ModelUser(
      ref: userRef,
      createdGReg: ModelRegistration(
        registeredBy: userId,
        registeredAt: createdAt,
      ),
      id: userId,
      pid: userPid,
      seed: seed,
    );
    final userPub = ModelUserPub(
      ref: userPubRef,
      createdGReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      id: userPid,
      displayName: displayName.toQueryable(),
      email: queryableEmail,
      emailEntries: {
        PRIMARY_EMAIL_ID: ModelEmailEntry(
          ref: primaryEmailRef,
          id: PRIMARY_EMAIL_ID,
          email: queryableEmail,
          createdGReg: ModelRegistration(
            registeredBy: userPid,
            registeredAt: createdAt,
          ),
        ),
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations([
      CreateOperation(model: user),
      CreateOperation(model: userPub),
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

  @visibleForTesting
  static Future<void> dbLazyDeleteUser({
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
    final createdByRelationshipIds = relationshipPool
        .where((e) => e.createdGReg?.registeredBy == userPid)
        .map((e) => e.id)
        .nonNulls;

    // Create delete operations for all relationships created by userPid.
    final createdByRelationshipDeleteOperations = createdByRelationshipIds.map(
      (e) => DeleteOperation(
        model: ModelRelationship(
          ref: Schema.relationshipsRef(relationshipId: e),
          id: e,
        ),
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
      (e) => RelationshipUtils.getLazyRemoveMembersOperation(
        serviceEnvironment: serviceEnvironment,
        relationshipId: e,
        memberPids: {userPid},
      ),
    );

    // Get all PIDs for organization pubs created by userPid within the organizationPubPool.
    final organizationPids = organizationPubPool
        .where((e) => e.createdGReg?.registeredBy == userPid)
        .map((e) => e.id)
        .nonNulls;

    // Fetch all organization IDs corresponding to the organizationPids.
    final organizationIds =
        (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelOrganization>(
              elements: organizationPids,
              collectionRef: Schema.organizationsRef(),
              fromJsonOrNull: ModelOrganization.fromJsonOrNull,
              elementKeys: {ModelOrganizationFields.pid.name},
            ).firstOrNull)
                ?.map((e) => e.id)
                .nonNulls ??
            [];

    // Create delete operations for all organization pubs created by userPid.
    final organizationPubDeleteOperations = organizationPids.map(
      (e) => DeleteOperation(
        model: ModelOrganizationPub(
          ref: Schema.organizationPubsRef(organizationPid: e),
        ),
      ),
    );

    // Create delete operations for all organizations created by userPid.
    final organizationDeleteOperations = organizationIds.map(
      (e) => DeleteOperation(
        model: ModelOrganization(
          ref: Schema.organizationsRef(organizationId: e),
        ),
      ),
    );

    // Get all PIDs fpr project pubs created by userPid within the projectPubPool.
    final projectPids = projectPubPool
        .where((e) => e.createdGReg?.registeredBy == userPid)
        .map((e) => e.id)
        .nonNulls;

    // Fetch all project IDs corresponding to the projectPids.
    final projectIds =
        (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelProject>(
              elements: projectPids,
              collectionRef: Schema.projectsRef(),
              fromJsonOrNull: ModelProject.fromJsonOrNull,
              elementKeys: {ModelProjectFields.pid.name},
            ).firstOrNull)
                ?.map((e) => e.id)
                .nonNulls ??
            [];

    // Create delete operations for all project pubs created by userPid.
    final projectPubsDeleteOperations = projectPids.map(
      (e) => DeleteOperation(
        model: ModelProjectPub(
          ref: Schema.projectPubsRef(projectPid: e),
        ),
      ),
    );

    // Create delete operations for all projects created by userPid.
    final projectDeleteOperations = projectIds.map(
      (e) => DeleteOperation(
        model: ModelProject(
          ref: Schema.projectsRef(projectId: e),
        ),
      ),
    );

    // Get all PIDs for jobs created by userPid within the jobPubPool.
    final jobPids =
        jobPubPool.where((e) => e.createdGReg?.registeredBy == userPid).map((e) => e.id).nonNulls;

    // Fetch all job IDs corresponding to the jobPids.
    final jobIds = (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelJob>(
          elements: jobPids,
          collectionRef: Schema.jobsRef(),
          fromJsonOrNull: ModelJob.fromJsonOrNull,
          elementKeys: {ModelJobFields.pid.name},
        ).firstOrNull)
            ?.map((e) => e.id)
            .nonNulls ??
        [];

    // Create delete operations for all job pubs created by userPid.
    final jobPubsDeleteOperations = jobPids.map(
      (e) => DeleteOperation(
        model: ModelJobPub(
          ref: Schema.jobPubsRef(jobPid: e),
        ),
      ),
    );

    // Create delete operations for all jobs created by userPid.
    final jobsDeleteOperations = jobIds.map(
      (e) => DeleteOperation(
        model: ModelJob(
          ref: Schema.jobsRef(jobId: e),
        ),
      ),
    );

    // Create delete operations for all events within relationships created by userPid.
    final relationshipEventDeleteOperations = (await Future.wait(
          createdByRelationshipIds.map(
            (e) => serviceEnvironment.databaseQueryBroker.getLazyDeleteCollectionOperations(
              collectionRef: Schema.relationshipEventsRef(relationshipId: e),
            ),
          ),
        ))
            .tryReduce((a, b) => [...a, ...b]) ??
        [];

    // Create a delete operation for the user document.
    final deleteUserOperation = DeleteOperation(
      model: ModelUser(
        ref: Schema.usersRef(userId: userId),
      ),
    );

    // Create a delete operation for the user pub document.
    final deleteUserPubOperation = DeleteOperation(
      model: ModelUserPub(
        ref: Schema.userPubsRef(userPid: userPid),
      ),
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
    final fileIds = filePool.where((e) => e.createdGReg?.registeredBy == userPid).map((e) => e.id);

    // Delete all files created by userPid.
    await Future.wait(
      fileIds.map(
        (id) {
          final ref = Schema.filesRef(fileId: id);
          return serviceEnvironment.fileServiceBroker.deleteFile(ref);
        },
      ),
    );
  }
}
