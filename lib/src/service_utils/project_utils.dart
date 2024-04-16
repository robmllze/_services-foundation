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

  static Future<Iterable<BatchWriteOperation>> getLazyDeleteOrganizationsOperations({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> organizationPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure organizationPids contains only organization pids.
    final temp = organizationPids.where((pid) => IdUtils.isOrganizationPid(pid)).toSet();
    assert(temp.length == organizationPids.length, 'organizationPids contains invalid pids.');
    organizationPids = temp;

    // Get all organization ids associated with organizationPids.
    final organizationIds =
        organizationPids.map((pid) => IdUtils.toOrganizationId(organizationPid: pid));

    // Get all relationships associated with organizationPids (ORGANIZATION_AND_USER, ORGANIZATION_AND_PROJECT).
    final organizationAssociatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: organizationPids).toSet();

    // Get all member pids associated with organizationPids, including user an project pids.
    final organizationAssociatedMemberPids = organizationAssociatedRelationshipPool.allMemberPids();

    // Get all project ids/pids associated with organizationPids.
    final projectPids = organizationAssociatedMemberPids.where((pid) => IdUtils.isProjectPid(pid));
    final projectIds = projectPids.map((pid) => IdUtils.toProjectId(projectPid: pid));

    // Get all relationships associated with projectPids (ORGANIZATION_AND_PROJECT, JOB_AND_PROJECT, PROJECT_AND_USER).
    final projectAssociatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: projectPids).toSet();

    // Get all member pids associated with projectPids, including organization, project and user pids.
    final projectAssociatedMemberPids = projectAssociatedRelationshipPool.allMemberPids();

    // Get all job ids/pids associated with projectPids.
    final jobPids = projectAssociatedMemberPids.where((pid) => IdUtils.isJobPid(pid));
    final jobIds = jobPids.map((pid) => IdUtils.toJobId(jobPid: pid));

    // Get all relationships associated with jobPids (JOB_AND_PROJECT, JOB_AND_USER).
    final jobAssociatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: jobPids).toSet();

    // Consolidate all associated relationship pools.
    final associatedRelationshipPool = Map.fromEntries([
      ...organizationAssociatedRelationshipPool.map((e) => MapEntry(e.id, e)),
      ...projectAssociatedRelationshipPool.map((e) => MapEntry(e.id, e)),
      ...jobAssociatedRelationshipPool.map((e) => MapEntry(e.id, e)),
    ]).values;

    final result = <BatchWriteOperation>[];

    // Add operations to delete all relationships associated with the organizationPid.
    for (final relationshipId in associatedRelationshipPool.allIds()) {
      result.addAll(
        // ignore: invalid_use_of_visible_for_testing_member
        await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      );
    }

    // Add operations to delete the organization, organization pub, project,
    // project pub, job and job pub documents.
    {
      result.addAll([
        for (final organizationId in organizationIds)
          BatchWriteOperation(
            Schema.organizationsRef(organizationId: organizationId),
            delete: true,
          ),
        for (final organizationPid in organizationPids)
          BatchWriteOperation(
            Schema.organizationPubsRef(organizationPid: organizationPid),
            delete: true,
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
        for (final jobId in jobIds)
          BatchWriteOperation(
            Schema.jobsRef(jobId: jobId),
            delete: true,
          ),
        for (final jobPid in jobPids)
          BatchWriteOperation(
            Schema.jobPubsRef(jobPid: jobPid),
            delete: true,
          ),
      ]);
    }

    return result;
  }
}
