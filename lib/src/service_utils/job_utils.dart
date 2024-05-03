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

  static ({
    Future<void> future,
    ModelJob job,
    ModelJobPub jobPub,
    ModelRelationship relationship,
  }) dbNewJob({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
    required String userPid,
    required String projectPid,
    required String displayName,
    required String description,
  }) {
    final now = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final jobId = IdUtils.newUuidV4();
    final jobPid = IdUtils.idToJobPid(
      seed: seed,
      jobId: jobId,
    );
    final job = ModelJob(
      createdAt: now,
      createdBy: userId,
      id: jobId,
      pid: jobPid,
      seed: seed,
    );
    final jobPub = ModelJobPub(
      createdAt: now,
      createdBy: userPid,
      whenOpened: {userPid: now},
      description: description,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      id: jobPid,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      createdBy: userPid,
      defType: RelationshipDefType.JOB_AND_PROJECT,
      id: relationshipId,
      memberPids: {
        userPid,
        jobPid,
        projectPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
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
    return (
      future: future,
      job: job,
      jobPub: jobPub,
      relationship: relationship,
    );
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
    final temp = jobPids.where((pid) => IdUtils.isJobPid(pid)).toList();
    assert(temp.length == jobPids.length, 'jobPids contains invalid pids.');
    jobPids = temp.toSet();

    // Get all relationships associated with jobPids (JOB_AND_PROJECT, JOB_AND_USER).
    final associatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: jobPids).toSet();

    // Fetch all associated PIDS.
    final jobIds = (await serviceEnvironment.databaseQueryBroker
                .streamJobsByPids(
                  pids: jobPids,
                )
                .firstOrNull)
            ?.map((e) => e.id)
            .nonNulls
            .toSet() ??
        {};

    printBlue('jobIds: $jobIds');

    assert(
      jobIds.length == jobPids.length,
      'jobIds length does not match jobPids length.',
    );

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
