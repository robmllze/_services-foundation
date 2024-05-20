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

abstract class PubHelperBase<T extends PublicBaseModel> {
  //
  //
  //

  final T pub;
  final Set<RelationshipDefType> baseRelationshipDefTypes;

  //
  //
  //

  const PubHelperBase({
    required this.pub,
    required this.baseRelationshipDefTypes,
  });

  //
  //
  //

  Iterable<ModelUserPub>? connectionPoolSnapshot();
  String? currentUserPidSnapshot();
  Iterable<ModelRelationship>? relationshipPoolSnapshot();
  Iterable<ModelUserPub>? userMemberPoolSnapshot();
  Iterable<ModelJobPub>? jobMemberPoolSnapshot();
  Iterable<ModelProjectPub>? projectMemberPoolSnapshot();
  Iterable<ModelOrganizationPub>? organizationMemberPoolSnapshot();
  ServiceEnvironment serviceEnvironment();
  RelationshipMemberService<T, DocumentServiceInterface<T>>? memberServiceSnapshot();

  Future<Iterable<BatchOperation>> Function({
    required ServiceEnvironment serviceEnvironment,
    required Iterable<String> pids,
    required Iterable<ModelRelationship> relationshipPool,
  }) get getLazyDeleteOperations;

  Type? get associatedType {
    final pid = this.pub.id;
    if (pid == null) {
      return null;
    } else if (IdUtils.isUserPid(pid)) {
      return ModelUserPub;
    } else if (IdUtils.isJobPid(pid)) {
      return ModelJobPub;
    } else if (IdUtils.isProjectPid(pid)) {
      return ModelProjectPub;
    } else if (IdUtils.isOrganizationPid(pid)) {
      return ModelOrganizationPub;
    } else {
      return null;
    }
  }

  DataRef? get associatedRef {
    final pid = this.pub.id;
    if (pid == null) {
      return null;
    } else if (IdUtils.isUserPid(pid)) {
      return Schema.userPubsRef(userPid: pid);
    } else if (IdUtils.isJobPid(pid)) {
      return Schema.jobPubsRef(jobPid: pid);
    } else if (IdUtils.isProjectPid(pid)) {
      return Schema.projectPubsRef(projectPid: pid);
    } else if (IdUtils.isOrganizationPid(pid)) {
      return Schema.organizationPubsRef(organizationPid: pid);
    } else {
      return null;
    }
  }

  //
  //
  //

  String? get pid => this.pub.id;

  String? creatorDisplayNameSnapshot() => this.creatorSnapshot()?.displayName?.nullIfEmpty;

  ModelUserPub? creatorSnapshot() =>
      this.connectionPoolSnapshot()?.firstWhereOrNull((e) => this.pub.createdBy == e.id);

  String? get displayName => this.pub.displayName?.nullIfEmpty;

  String? get description => this.pub.description?.nullIfEmpty;

  String? get shortDescription {
    final hasData = this.description != null;
    if (hasData) {
      const MAX_LENGTH = 50;
      final a = this.description!.replaceAll(RegExp(r'\s+'), ' ');
      final b = a.substring(0, min(MAX_LENGTH, a.length)) + (a.length > MAX_LENGTH ? '...' : '');
      return b;
    } else {
      return null;
    }
  }

  bool isCurrentUserCreatorSnapshot() {
    final pid = this.currentUserPidSnapshot();
    final hasData = pid != null;
    return (hasData ? this.pub.createdBy == pid : null) ?? false;
  }

  bool isCurrentUserAssociatedRelationshipMemberSnapshot() {
    final pid = this.currentUserPidSnapshot();
    final associatedRelationship = this.firstAssociatedRelationshipSnapshot();
    final hasData = pid != null && associatedRelationship != null;
    return (hasData ? associatedRelationship.memberPids?.contains(pid) : null) ?? false;
  }

  ModelRelationship? firstAssociatedRelationshipSnapshot() {
    final hasData = this.pid != null;
    return hasData ? this.getAssociatedRelationshipPoolSnapshot()?.firstOrNull : null;
  }

  Iterable<ModelRelationship>? getAssociatedRelationshipPoolSnapshot() {
    final hasData = this.pid != null;
    return hasData
        ? () {
            var a = this.relationshipPoolSnapshot();
            a = a?.filterByEveryMember(
              memberPids: {this.pid!},
            );
            if (this.baseRelationshipDefTypes.isNotEmpty) {
              a = a?.filterByDefType(defTypes: this.baseRelationshipDefTypes);
            }
            return a;
          }()
        : null;
  }

  ModelUserPub? firstAssociatedUserMemberSnapshot() {
    final pid = this.firstAssociatedUserPidSnapshot();
    final hasData = pid != null;
    return hasData ? this.userMemberPoolSnapshot()?.firstWhereOrNull((e) => e.id == pid) : null;
  }

  ModelJobPub? firstAssociatedJobMemberSnapshot() {
    final pid = this.firstAssociatedJobPidSnapshot();
    final hasData = pid != null;
    return hasData ? this.jobMemberPoolSnapshot()?.firstWhereOrNull((e) => e.id == pid) : null;
  }

  ModelProjectPub? firstAssociatedProjectMemberSnapshot() {
    final pid = this.firstAssociatedProjectPidSnapshot();
    final hasData = pid != null;
    return hasData ? this.projectMemberPoolSnapshot()?.firstWhereOrNull((e) => e.id == pid) : null;
  }

  ModelOrganizationPub? firstAssociatedOrganizationMemberSnapshot() {
    final pid = this.firstAssociatedOrganizationPidSnapshot();
    final hasData = pid != null;
    return hasData
        ? this.organizationMemberPoolSnapshot()?.firstWhereOrNull((e) => e.id == pid)
        : null;
  }

  String? firstAssociatedUserPidSnapshot() {
    return this.firstAssociatedPidSnapshotWhere(IdUtils.isUserPid);
  }

  String? firstAssociatedPidSnapshotWhere(bool Function(String pid) test) {
    return this.firstAssociatedRelationshipSnapshot()?.memberPids?.firstWhere(test);
  }

  String? firstAssociatedJobPidSnapshot() {
    return this.firstAssociatedPidSnapshotWhere(IdUtils.isJobPid);
  }

  String? firstAssociatedProjectPidSnapshot() {
    return this.firstAssociatedPidSnapshotWhere(IdUtils.isProjectPid);
  }

  String? firstAssociatedOrganizationPidSnapshot() {
    return this.firstAssociatedPidSnapshotWhere(IdUtils.isOrganizationPid);
  }

  /// Adds the current user as a member to the associated relationship.
  Future<void> dbAddCurrentUserAsMemberToAssocatedRelationship() async {
    final currentUserPid = this.currentUserPidSnapshot();
    final associatedRelationship = this.firstAssociatedRelationshipSnapshot();
    final hasData = currentUserPid != null && associatedRelationship != null;
    if (hasData) {
      await RelationshipUtils.dbAddMembers(
        serviceEnvironment: this.serviceEnvironment(),
        relationship: associatedRelationship,
        memberPids: {currentUserPid},
      );
    }
  }

  /// Removes the current user as a member from the associated relationship.
  Future<void> dbRemoveCurrentUserAsMemberFromAssociatedRelationship() async {
    final currentUserPid = this.currentUserPidSnapshot();
    final associatedRelationship = this.firstAssociatedRelationshipSnapshot();
    final hasData = currentUserPid != null && associatedRelationship != null;
    if (hasData) {
      await RelationshipUtils.dbRemoveMembers(
        serviceEnvironment: this.serviceEnvironment(),
        relationship: associatedRelationship,
        memberPids: {currentUserPid},
      );
    }
  }

  Future<void> dbDelete() async {
    final relationshipPool = this.relationshipPoolSnapshot();
    final hasData = this.pid != null && relationshipPool != null;
    if (hasData) {
      this.memberServiceSnapshot()?.removeMembers({this.pid!});
      final operations = await this.getLazyDeleteOperations(
        serviceEnvironment: this.serviceEnvironment(),
        pids: {this.pid!},
        relationshipPool: relationshipPool,
      );
      await this.serviceEnvironment().databaseServiceBroker.runBatchOperations(operations);
    }
  }
}
