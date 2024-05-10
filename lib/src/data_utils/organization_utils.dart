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

  static ({
    Future<void> future,
    ModelOrganization organization,
    ModelOrganizationPub organizationPub,
    ModelRelationship relationship,
  }) dbNewOrganization({
    required ServiceEnvironment serviceEnvironment,
    required String userId,
    required String userPid,
    required String displayName,
    required String description,
  }) {
    final now = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final organizationId = IdUtils.newUuidV4();
    final organizationPid = IdUtils.idToOrganizationPid(
      seed: seed,
      organizationId: organizationId,
    );
    final organization = ModelOrganization(
      createdAt: now,
      createdBy: userId,
      id: organizationId,
      pid: organizationPid,
      seed: seed,
    );
    final organizationPub = ModelOrganizationPub(
      createdAt: now,
      createdBy: userPid,
      description: description,
      displayName: displayName,
      displayNameSearchable: displayName.toLowerCase(),
      id: organizationPid,
    );

    final relationshipId = IdUtils.newRelationshipId();
    final relationship = ModelRelationship(
      createdAt: now,
      createdBy: userPid,
      defType: RelationshipDefType.USER_AND_ORGANIZATION,
      id: relationshipId,
      memberPids: {
        userPid,
        organizationPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(
          ref: Schema.organizationsRef(organizationId: organizationId),
          model: organization,
        ),
        CreateOperation(
          ref: Schema.organizationPubsRef(organizationPid: organizationPid),
          model: organizationPub,
        ),
        CreateOperation(
          ref: Schema.relationshipsRef(relationshipId: relationshipId),
          model: relationship,
        ),
      ],
    );
    return (
      future: future,
      organization: organization,
      organizationPub: organizationPub,
      relationship: relationship,
    );
  }

  //
  //
  //

  @visibleForTesting
  static Future<Iterable<BatchOperation>> getLazyDeleteOperations({
    required ServiceEnvironment serviceEnvironment,
    required Set<String> organizationPids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure organizationPids contains valid pids.
    final temp = organizationPids.where((pid) => IdUtils.isOrganizationPid(pid)).toSet();
    assert(temp.length == organizationPids.length, 'organizationPids contains invalid pids.');
    organizationPids = temp;

    // Get all relationships associated with organizationPids (ORGANIZATION_AND_USER, ORGANIZATION_AND_PROJECT).
    final associatedRelationshipPool =
        relationshipPool.filterByAnyMember(memberPids: organizationPids).toSet();

    // Get all member pids associated with organizationPids, including user an project pids.
    final organizationAssociatedMemberPids = associatedRelationshipPool.allMemberPids();

    // Get all project ids/pids associated with organizationPids.
    final projectPids = organizationAssociatedMemberPids.where((pid) => IdUtils.isProjectPid(pid));

    // Fetch all associated PIDS.
    final organizationIds =
        (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelOrganization>(
              elements: organizationPids,
              collectionRef: Schema.organizationsRef(),
              fromJsonOrNull: ModelOrganization.fromJsonOrNull,
              elementKeys: {ModelOrganization.K_PID},
            ).firstOrNull)
                ?.map((e) => e.id)
                .nonNulls
                .toSet() ??
            {};

    // TODO: Address the issue below.

    // assert(
    //   organizationIds.length == organizationPids.length,
    //   'organizationIds length does not match organizationPids length.',
    // );

    // Return operations to delete everything associated with organizationPids.
    return {
      for (final relationshipId in associatedRelationshipPool.allIds())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipId,
        ),
      for (final organizationId in organizationIds)
        DeleteOperation(
          ref: Schema.organizationsRef(organizationId: organizationId),
        ),
      for (final organizationPid in organizationPids)
        DeleteOperation(
          ref: Schema.organizationPubsRef(organizationPid: organizationPid),
        ),
      ...await ProjectUtils.getLazyDeleteOperations(
        serviceEnvironment: serviceEnvironment,
        projectPids: projectPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
