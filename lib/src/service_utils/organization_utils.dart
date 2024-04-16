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

final class OrganizationUtils {
  //
  //
  //

  OrganizationUtils._();

  //
  //
  //

  static Future<void> createNewOrganization({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String displayName,
    required String description,
  }) async {
    final now = DateTime.now();
    final organizationId = IdUtils.newId();
    final organizationPid = IdUtils.toOrganizationPid(organizationId: organizationId);
    final organization = ModelOrganization(
      id: organizationId,
      pid: organizationPid,
      createdAt: now,
    );
    final organizationPub = ModelOrganizationPub(
      id: organizationPid,
      organizationId: organizationId,
      openedAt: now,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      description: description,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      id: relationshipId,
      defType: RelationshipDefType.ORGANIZATION_AND_USER,
      def: ModelUserAndOrgRelDef(
        userPid: userPid,
        organizationPid: organizationPid,
      ).toGenericModel(),
      memberPids: {
        userPid,
        organizationPid,
      },
    );

    await serviceEnvironment.databaseServiceBroker.batchWrite(
      [
        BatchWriteOperation(
          Schema.organizationsRef(organizationId: organizationId),
          model: organization,
        ),
        BatchWriteOperation(
          Schema.organizationPubsRef(organizationPid: organizationPid),
          model: organizationPub,
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

  static Future<Iterable<BatchWriteOperation>> getLazyDeleteOrganizationsOperations({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> organizationPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure organizationPids contains valid pids.
    final temp = organizationPids.where((pid) => IdUtils.isOrganizationPid(pid)).toSet();
    assert(temp.length == organizationPids.length, 'organizationPids contains invalid pids.');
    organizationPids = temp;

    // Get all organization ids associated with organizationPids.
    final organizationIds =
        organizationPids.map((pid) => IdUtils.toOrganizationId(organizationPid: pid));

    // Get all relationships associated with organizationPids (ORGANIZATION_AND_USER, ORGANIZATION_AND_PROJECT).
    final associatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: organizationPids).toSet();

    // Get all member pids associated with organizationPids, including user an project pids.
    final organizationAssociatedMemberPids = associatedRelationshipPool.allMemberPids();

    // Get all project ids/pids associated with organizationPids.
    final projectPids = organizationAssociatedMemberPids.where((pid) => IdUtils.isProjectPid(pid));

    // Return operations to delete everything associated with organizationPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        // ignore: invalid_use_of_visible_for_testing_member
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
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
      ...await ProjectUtils.getLazyDeleteProjectsOperations(
        serviceEnvironment: serviceEnvironment,
        projectPids: projectPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
