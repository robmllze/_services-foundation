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
    final createdAt = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final jobId = IdUtils.newUuidV4();
    final jobRef = Schema.jobsRef(jobId: jobId);
    final jobPid = IdUtils.idToJobPid(
      seed: seed,
      jobId: jobId,
    );
    final job = ModelJob(
      ref: jobRef,
      createdReg: ModelRegistration(
        registeredBy: userId,
        registeredAt: createdAt,
      ),
      id: jobId,
      pid: jobPid,
      seed: seed,
    );
    final jobPubRef = Schema.jobPubsRef(jobPid: jobPid);
    final jobPub = ModelJobPub(
      ref: jobPubRef,
      createdReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      description: description,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      id: jobPid,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      ref: Schema.relationshipsRef(relationshipId: relationshipId),
      createdReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      type: RelationshipType.JOB_AND_PROJECT,
      id: relationshipId,
      memberPids: {
        userPid,
        jobPid,
        projectPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(model: job),
        CreateOperation(model: jobPub),
        CreateOperation(model: relationship),
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
    required Iterable<String> pids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure jobPids contains valid pids.
    final temp = pids.where((pid) => IdUtils.isJobPid(pid)).toList();
    assert(temp.length == pids.length, 'jobPids contains invalid pids.');
    pids = temp.toSet();

    // Get all relationships associated with jobPids (JOB_AND_PROJECT, JOB_AND_USER).
    final associatedRelationshipPool = relationshipPool.filterByAnyMember(memberPids: pids).toSet();

    // Fetch all associated PIDS.
    final jobIds = (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelJob>(
          elements: pids,
          collectionRef: Schema.jobsRef(),
          fromJsonOrNull: ModelJob.fromJsonOrNull,
          elementKeys: {ModelJob.K_PID},
        ).firstOrNull)
            ?.map((e) => e.id)
            .nonNulls
            .toSet() ??
        {};

    // TODO: Address the issue below.

    // assert(
    //   jobIds.length == jobPids.length,
    //   'jobIds length does not match jobPids length.',
    // );

    // Return operations to delete everything associated with jobPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      for (final jobId in jobIds)
        DeleteOperation(
          model: ModelJob(
            ref: Schema.jobsRef(
              jobId: jobId,
            ),
          ),
        ),
      for (final jobPid in pids)
        DeleteOperation(
          model: ModelJobPub(
            ref: Schema.jobPubsRef(
              jobPid: jobPid,
            ),
          ),
        ),
    };
  }
}
