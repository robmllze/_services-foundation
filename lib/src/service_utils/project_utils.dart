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
    final now = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final projectId = IdUtils.newUuidV4();
    final projectPid = IdUtils.idToProjectPid(
      seed: seed,
      projectId: projectId,
    );
    final project = ModelProject(
      createdAt: now,
      createdBy: userId,
      id: projectId,
      pid: projectPid,
      seed: seed,
    );
    final projectPub = ModelProjectPub(
      createdAt: now,
      createdBy: userPid,
      whenOpened: {userPid: now},
      id: projectPid,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      createdBy: userPid,
      id: relationshipId,
      defType: RelationshipDefType.PROJECT_AND_ORGANIZATION,
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

    // Fetch all associated PIDS.
    final projectIds = (await serviceEnvironment.databaseQueryBroker
                .streamByWhereInElements<ModelProject>(
                  elements: projectPids,
                  collectionRef: Schema.projectsRef(),
                  fromJsonOrNull: ModelProject.fromJsonOrNull,
                  elementKeys: {ModelProject.K_PID},
                )
                .firstOrNull)
            ?.map((e) => e.id)
            .nonNulls
            .toSet() ??
        {};

    assert(
      projectIds.length == projectPids.length,
      'projectIds length does not match projectPids length.',
    );

    // Return operations to delete everything associated with projectPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
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
        jobPids: jobPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
