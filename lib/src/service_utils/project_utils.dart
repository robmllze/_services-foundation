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

  static Future<void> createNewProject({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String organizationPid,
    required String displayName,
    required String description,
  }) async {
    final now = DateTime.now();
    final projectId = IdUtils.newId();
    final projectPid = IdUtils.toProjectPid(projectId: projectId);
    final project = ModelProject(
      id: projectId,
      pid: projectPid,
      createdAt: now,
    );
    final projectPub = ModelProjectPub(
      id: projectPid,
      projectId: projectId,
      openedAt: now,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      id: relationshipId,
      defType: RelationshipDefType.ORGANIZATION_AND_PROJECT,
      memberPids: {
        userPid,
        projectPid,
        organizationPid,
      },
    );

    await serviceEnvironment.databaseServiceBroker.batchWrite(
      [
        BatchWriteOperation(
          Schema.projectsRef(projectId: projectId),
          model: project,
        ),
        BatchWriteOperation(
          Schema.projectPubsRef(projectPid: projectPid),
          model: projectPub,
        ),
        BatchWriteOperation(
          Schema.relationshipsRef(relationshipId: relationshipId),
          model: relationship,
        ),
      ],
    );
  }

  //
  //
  //

  static Future<Iterable<BatchWriteOperation>> getLazyDeleteProjectsOperations({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<String> projectPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure projectPids contains valid pids.
    final temp = projectPids.where((pid) => IdUtils.isProjectPid(pid));
    assert(temp.length == projectPids.length, 'projectPids contains invalid pids.');
    projectPids = temp.toSet();

    // Get all project ids associated with projectPids.
    final projectIds = projectPids.map((pid) => IdUtils.toProjectId(projectPid: pid));

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
        // ignore: invalid_use_of_visible_for_testing_member
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      for (final projectId in projectIds)
        BatchWriteOperation(
          Schema.projectsRef(projectId: projectId),
          delete: true,
        ),
      for (final projectPid in projectPids)
        BatchWriteOperation(
          Schema.projectPubsRef(projectPid: projectPid),
          delete: true,
        ),
      ...await JobUtils.getLazyDeleteJobsOperations(
        serviceEnvironment: serviceEnvironment,
        jobPids: jobPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
