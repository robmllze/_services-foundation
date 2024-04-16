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
