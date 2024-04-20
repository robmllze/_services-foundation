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

  // static bool isRelationshipCreator({
  //   required Iterable<ModelRelationship> relationshipPool,
  //   required String currentUserPid,
  //   required String organizationPid,
  // }) {
  //   final organizationRelationship = relationshipPool.filterByDefType(
  //     defTypes: {RelationshipDefType.ORGANIZATION_AND_USER},
  //   ).filterByAnyMember(memberPids: {organizationPid}).firstOrNull;
  //   final createdByPid = organizationRelationship?.createdByPid;
  //   final isCreator = currentUserPid == createdByPid;
  //   return isCreator;
  // }

  //
  //
  //

  static Future<(ModelOrganization, ModelOrganizationPub, ModelRelationship)>
      createNewOrganization({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String displayName,
    required String description,
  }) async {
    final now = DateTime.now();
    final organizationId = IdUtils.newId();
    final organizationPid = IdUtils.toOrganizationPid(organizationId: organizationId);
    final userId = IdUtils.toUserId(userPid: userPid);
    final organization = ModelOrganization(
      createdAt: now,
      createdById: userId,
      id: organizationId,
      pid: organizationPid,
    );
    final organizationPub = ModelOrganizationPub(
      createdAt: now,
      createdByPid: userPid,
      description: description,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      id: organizationPid,
      openedAt: now,
      organizationId: organizationId,
    );
    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      createdByPid: userPid,
      defType: RelationshipDefType.ORGANIZATION_AND_USER,
      id: relationshipId,
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
    return (organization, organizationPub, relationship);
  }

  //
  //
  //

  static Future<Iterable<BatchWriteOperation>> getLazyDeleteOperations({
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
      ...await ProjectUtils.getLazyDeleteOperations(
        serviceEnvironment: serviceEnvironment,
        projectPids: projectPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
