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
    final createdAt = DateTime.now();
    final seed = IdUtils.newUuidV4();
    final organizationId = IdUtils.newUuidV4();
    final organizationRef = Schema.organizationsRef(organizationId: organizationId);
    final organizationPid = IdUtils.idToOrganizationPid(
      seed: seed,
      organizationId: organizationId,
    );

    final organization = ModelOrganization(
      ref: organizationRef,
      createdGReg: ModelRegistration(
        registeredBy: userId,
        registeredAt: createdAt,
      ),
      id: organizationId,
      pid: organizationPid,
      seed: seed,
    );
    final organizationPubRef = Schema.organizationPubsRef(organizationPid: organizationPid);
    final organizationPub = ModelOrganizationPub(
      ref: organizationPubRef,
      createdGReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      description: description,
      displayName: displayName.toQueryable(),
      id: organizationPid,
    );

    final relationshipId = IdUtils.newRelationshipId();
    final relationshipRef = Schema.relationshipsRef(relationshipId: relationshipId);
    final relationship = ModelRelationship(
      ref: relationshipRef,
      createdGReg: ModelRegistration(
        registeredBy: userPid,
        registeredAt: createdAt,
      ),
      type: RelationshipType.USER_AND_ORGANIZATION,
      id: relationshipId,
      memberPids: {
        userPid,
        organizationPid,
      },
    );
    final future = serviceEnvironment.databaseServiceBroker.runBatchOperations(
      [
        CreateOperation(model: organization),
        CreateOperation(model: organizationPub),
        CreateOperation(model: relationship),
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
    required Iterable<String> pids,
    required Iterable<ModelRelationship> relationshipPool,
  }) async {
    // Ensure organizationPids contains valid pids.
    final temp = pids.where((pid) => IdUtils.isOrganizationPid(pid)).toSet();
    assert(temp.length == pids.length, 'organizationPids contains invalid pids.');
    pids = temp;

    // Get all relationships associated with organizationPids (ORGANIZATION_AND_USER, ORGANIZATION_AND_PROJECT).
    final associatedRelationshipPool = relationshipPool.filterInAnyMember(memberPids: pids).toSet();

    // Get all member pids associated with organizationPids, including user an project pids.
    final organizationAssociatedMemberPids = associatedRelationshipPool.allMemberPids();

    // Get all project ids/pids associated with organizationPids.
    final projectPids = organizationAssociatedMemberPids.where((pid) => IdUtils.isProjectPid(pid));

    // Fetch all associated PIDS.
    final organizationIds =
        (await serviceEnvironment.databaseQueryBroker.streamByWhereInElements<ModelOrganization>(
              elements: pids,
              collectionRef: Schema.organizationsRef(),
              fromJsonOrNull: ModelOrganization.fromJsonOrNull,
              elementKeys: {ModelOrganizationFields.pid.name},
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
      for (final relationshipRef in associatedRelationshipPool.allDataRefs())
        ...await RelationshipUtils.getLazyDeleteRelationshipOperations(
          serviceEnvironment: serviceEnvironment,
          relationshipId: relationshipRef.id!,
        ),
      for (final organizationId in organizationIds)
        DeleteOperation(
          model: ModelOrganization(
            ref: Schema.organizationsRef(
              organizationId: organizationId,
            ),
          ),
        ),
      for (final organizationPid in pids)
        DeleteOperation(
          model: ModelOrganizationPub(
            ref: Schema.organizationPubsRef(
              organizationPid: organizationPid,
            ),
          ),
        ),
      ...await ProjectUtils.getLazyDeleteOperations(
        serviceEnvironment: serviceEnvironment,
        pids: projectPids,
        relationshipPool: relationshipPool,
      ),
    };
  }
}
