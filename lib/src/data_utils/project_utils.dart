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

final class ProjectUtils {
  //
  //
  //

  ProjectUtils._();

  //
  //
  //

  static ({
    Future<void> future,
    ModelProject project,
    ModelProjectPub projectPub,
    ModelRelationship relationship,
  }) dbNewProject({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
    required String userPid,
    required String organizationPid,
    required String displayName,
    required String description,
  }) {
    final createdAt = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final projectId = IdUtils.newUuidV4();
    final projectRef = Schema.projectsRef(projectId: projectId);
    final projectPid = IdUtils.idToProjectPid(
      seed: seed,
      projectId: projectId,
    );

    final project = ModelProject(
      ref: projectRef,
      createdReg: ModelRegistration(
        registeredBy: userId,
        registeredAt: createdAt,
      ),
      id: projectId,
      pid: projectPid,
      seed: seed,
    );
    final projectPubRef = Schema.projectPubsRef(projectPid: projectPid);
    final projectPub = ModelProjectPub(
      ref: projectPubRef,
      createdReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      id: projectPid,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    final relationship = ModelRelationship(
      ref: relationshipRef,
      createdReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      id: relationshipId,
      type: RelationshipType.PROJECT_AND_ORGANIZATION,
      memberPids: {
        userPid,
        projectPid,
        organizationPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(model: project),
        CreateOperation(model: projectPub),
        CreateOperation(model: relationship),
      ],
    );
    return (
      future: future,
      project: project,
      projectPub: projectPub,
      relationship: relationship,
    );
  }

  //
  //
  //

  @visibleForTesting
  static Future<Iterable<BatchOperation>> getLazyDeleteOperations({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<String> pids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure projectPids contains valid pids.
    final temp = pids.where((pid) => IdUtils.isProjectPid(pid));
    assert(temp.length == pids.length, 'projectPids contains invalid pids.');
    pids = temp.toSet();

    // Get all relationships associated with projectPids (ORGANIZATION_AND_PROJECT, JOB_AND_PROJECT, PROJECT_AND_USER).
    final associatedRelationshipPool = relationshipPool.filterByAnyMember(memberPids: pids).toSet();

    // Get all member pids associated with projectPids, including organization, project and user pids.
    final projectAssociatedMemberPids = associatedRelationshipPool.allMemberPids();

    // Get all job ids/pids associated with projectPids.
    final jobPids = projectAssociatedMemberPids.where((pid) => IdUtils.isJobPid(pid));

    // Fetch all associated PIDS.
    final projectIds =
        (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelProject>(
              elements: pids,
              collectionRef: Schema.projectsRef(),
              fromJsonOrNull: ModelProject.fromJsonOrNull,
              elementKeys: {ModelProject.K_PID},
            ).firstOrNull)
                ?.map((e) => e.id)
                .nonNulls
                .toSet() ??
            {};

    // TODO: Address the issue below.

    // assert(
    //   projectIds.length == projectPids.length,
    //   'projectIds length does not match projectPids length.',
    // );

    // Return operations to delete everything associated with projectPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      for (final projectId in projectIds)
        DeleteOperation(
          model: ModelProject(
            ref: Schema.projectsRef(
              projectId: projectId,
            ),
          ),
        ),
      for (final projectPid in pids)
        DeleteOperation(
          model: ModelProjectPub(
            ref: Schema.projectPubsRef(
              projectPid: projectPid,
            ),
          ),
        ),
      ...await JobUtils.getLazyDeleteOperations(
        serviceEnvironment: serviceEnvironment,
        pids: jobPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
