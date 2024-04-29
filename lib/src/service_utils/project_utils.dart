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

  static (
    Future<void>,
    ModelProject,
    ModelProjectPub,
    ModelRelationship,
  ) dbNewProject({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
    required String userPid,
    required String organizationPid,
    required String displayName,
    required String description,
  }) {
    final now = DateTime.now();
    final seedId = IdUtils.newUuidV4();
    final projectId = IdUtils.newUuidV4();
    final projectPid = IdUtils.idToProjectPid(
      seedId: seedId,
      projectId: projectId,
    );
    final project = ModelProject(
      createdAt: now,
      creatorId: userId,
      id: projectId,
      pid: projectPid,
      seedId: seedId,
    );
    final projectPub = ModelProjectPub(
      createdAt: now,
      creatorPid: userPid,
      id: projectPid,
      openedAt: now,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      creatorPid: userPid,
      id: relationshipId,
      defType: RelationshipDefType.ORGANIZATION_AND_PROJECT,
      memberPids: {
        userPid,
        projectPid,
        organizationPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(
          ref: Schema.projectsRef(projectId: projectId),
          model: project,
        ),
        CreateOperation(
          ref: Schema.projectPubsRef(projectPid: projectPid),
          model: projectPub,
        ),
        CreateOperation(
          ref: Schema.relationshipsRef(relationshipId: relationshipId),
          model: relationship,
        ),
      ],
    );
    return (
      future,
      project,
      projectPub,
      relationship,
    );
  }

  //
  //
  //

  Future<void> addProjectPubService({
    required ServiceEnvironment serviceEnvironment,
    required ProjectMemberService projectMemberService,
    required ModelProjectPub projectPub,
  }) async {
    final pid = projectPub.id!;
    final service = ProjectPubService(
      serviceEnvironment: serviceEnvironment,
      id: pid,
    );
    await service.pValue.set(projectPub);
    await projectMemberService.pMemberServicePool.update((e) => e..[pid] = service);
  }

  //
  //
  //

  @visibleForTesting
  static Future<Iterable<BatchOperation>> getLazyDeleteOperations({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<String>? projectIds,
    required Iterable<String> projectPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure projectPids contains valid pids.
    final temp = projectPids.where((pid) => IdUtils.isProjectPid(pid));
    assert(temp.length == projectPids.length, 'projectPids contains invalid pids.');
    projectPids = temp.toSet();

    // Get all relationships associated with projectPids (ORGANIZATION_AND_PROJECT, JOB_AND_PROJECT, PROJECT_AND_USER).
    final associatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: projectPids).toSet();

    // Get all member pids associated with projectPids, including organization, project and user pids.
    final projectAssociatedMemberPids = associatedRelationshipPool.allMemberPids();

    // Get all job ids/pids associated with projectPids.
    final jobPids = projectAssociatedMemberPids.where((pid) => IdUtils.isJobPid(pid));

    // Return operations to delete everything associated with projectPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      if (projectIds != null)
        for (final projectId in projectIds)
          DeleteOperation(
            ref: Schema.projectsRef(projectId: projectId),
          ),
      for (final projectPid in projectPids)
        DeleteOperation(
          ref: Schema.projectPubsRef(projectPid: projectPid),
        ),
      ...await JobUtils.getLazyDeleteOperations(
        serviceEnvironment: serviceEnvironment,
        jobIds: null,
        jobPids: jobPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
