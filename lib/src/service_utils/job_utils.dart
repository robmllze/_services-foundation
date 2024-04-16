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

  Future<void> lazyDeleteJobs({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> jobPid,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    //   {
    //     // Get all relationship IDs associated with the jobPid and users.
    //     final relationshipIds = relationshipPool.filterByEveryMember(
    //       memberPids: {jobPid},
    //     ).filterByDefType(
    //       defTypes: {RelationshipDefType.JOB_AND_USER},
    //     ).allIds();

    //     // Delete all events associated with the jobPid and users.
    //     for (final relationshipId in relationshipIds) {
    //       // ignore: invalid_use_of_visible_for_testing_member
    //       await RelationshipUtils.lazyDeleteRelationshipEventsCollection(
    //         serviceEnvironment: serviceEnvironment,
    //         relationshipId: relationshipId,
    //       );
    //     }
    //   }

    //   await serviceEnvironment.databaseServiceBroker.batchWrite(
    //     [
    //       BatchWriteOperation(
    //         Schema.organizationsRef(
    //             organizationId: IdUtils.toOrganizationId(organizationPid: organizationPid)),
    //         delete: true,
    //       ),
    //       BatchWriteOperation(
    //         Schema.organizationPubsRef(
    //           organizationPid: organizationPid,
    //         ),
    //         delete: true,
    //       ),
    //       ...relationshipIds.map(
    //         (relationshipId) => BatchWriteOperation(
    //           Schema.relationshipsRef(
    //             relationshipId: relationshipId,
    //           ),
    //           delete: true,
    //         ),
    //       ),
    //     ],
    //   );
  }
}
