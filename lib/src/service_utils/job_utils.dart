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

final class JobUtils {
  //
  //
  //

  static Future<void> createNewJob({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String projectPid,
    required String displayName,
    required String description,
  }) async {
    final now = DateTime.now();
    final jobId = IdUtils.newId();
    final jobPid = IdUtils.toJobPid(jobId: jobId);
    final job = ModelJob(
      id: jobPid,
      pid: jobPid,
      createdAt: now,
    );
    final jobPub = ModelProjectPub(
      id: jobPid,
      projectId: jobId,
      openedAt: now,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      id: relationshipId,
      defType: RelationshipDefType.JOB_AND_PROJECT,
      memberPids: {
        userPid,
        jobPid,
        projectPid,
      },
    );

    await serviceEnvironment.databaseServiceBroker.batchWrite(
      [
        BatchWriteOperation(
          Schema.jobsRef(jobId: jobId),
          model: job,
        ),
        BatchWriteOperation(
          Schema.jobPubsRef(jobPid: jobPid),
          model: jobPub,
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

  static Future<Iterable<BatchWriteOperation>> getLazyDeleteJobsOperations({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<String> jobPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure jobPids contains valid pids.
    final temp = jobPids.where((pid) => IdUtils.isJobPid(pid));
    assert(temp.length == jobPids.length, 'jobPids contains invalid pids.');
    jobPids = temp.toSet();

    // Get all job ids associated with jobPids.
    final jobIds = jobPids.map((pid) => IdUtils.toJobId(jobPid: pid));

    // Get all relationships associated with jobPids (JOB_AND_PROJECT, JOB_AND_USER).
    final associatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: jobPids).toSet();

    // Return operations to delete everything associated with jobPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        // ignore: invalid_use_of_visible_for_testing_member
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
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
    };
  }
}
