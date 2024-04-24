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

  JobUtils._();

  //
  //
  //

  static Future<(ModelJob, ModelJobPub, ModelRelationship)> dbNewJob({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String projectPid,
    required String displayName,
    required String description,
  }) async {
    final now = DateTime.now();
    final jobId = IdUtils.newId();
    final jobPid = IdUtils.toJobPid(jobId: jobId);
    final userId = IdUtils.toUserId(userPid: userPid);
    final job = ModelJob(
      createdAt: now,
      createdById: userId,
      id: jobPid,
      pid: jobPid,
    );
    final jobPub = ModelJobPub(
      createdAt: now,
      createdByPid: userPid,
      description: description,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      id: jobPid,
      jobId: jobId,
      openedAt: now,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      createdByPid: userPid,
      defType: RelationshipDefType.JOB_AND_PROJECT,
      id: relationshipId,
      memberPids: {
        userPid,
        jobPid,
        projectPid,
      },
    );

    await serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(
          ref: Schema.jobsRef(jobId: jobId),
          model: job,
        ),
        CreateOperation(
          ref: Schema.jobPubsRef(jobPid: jobPid),
          model: jobPub,
        ),
        CreateOperation(
          ref: Schema.relationshipsRef(relationshipId: relationshipId),
          model: relationship,
        ),
      ],
    );
    return (job, jobPub, relationship);
  }

  //
  //
  //

  @visibleForTesting
  static Future<Iterable<BatchOperation>> getLazyDeleteOperations({
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
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      for (final jobId in jobIds)
        DeleteOperation(
          ref: Schema.jobsRef(jobId: jobId),
        ),
      for (final jobPid in jobPids)
        DeleteOperation(
          ref: Schema.jobPubsRef(jobPid: jobPid),
        ),
    };
  }
}
