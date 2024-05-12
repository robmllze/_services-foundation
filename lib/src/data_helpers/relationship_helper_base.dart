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

abstract class RelationshipHelperBase {
  //
  //
  //

  final String relationshipId;

  //
  //
  //

  const RelationshipHelperBase({required this.relationshipId});

  //
  //
  //

  String? currentUserPidSnapshot();
  Iterable<ModelRelationship>? relationshipPoolSnapshot();
  RelationshipService? relationshipServiceSnapshot();

  //
  //
  //

  @nonVirtual
  List<RelationshipDefType>? relationshipDefTypesSnapshot() =>
      RelationshipDefType.fromMemberPids(this.relationshipSnapshot()?.memberPids);

  //
  //
  //

  @nonVirtual
  String? associatedPubPrefix() {
    if (this.isProjectAndOrganizationRelationshipSnapshot() == true) {
      return IdUtils.ORGANIZATION_PID_PREFIX;
    } else if (this.isJobAndProjectRelationshipSnapshot() == true) {
      return IdUtils.PROJECT_PID_PREFIX;
    } else if (this.isUserAndJobRelationshipSnapshot() == true) {
      return IdUtils.JOB_PID_PREFIX;
    } else if (this.isUserAndUserRelationshipSnapshot() == true) {
      return IdUtils.USER_PID_PREFIX;
    } else {
      return null;
    }
  }

  //
  //
  //

  @nonVirtual
  String? primaryPidSnapshot() {
    final relationship = this.relationshipSnapshot();
    final prefix = this.associatedPubPrefix();
    final pids =
        prefix != null ? relationship?.extractMemberPids(memberPidPrefixes: {prefix}) : null;
    final pid = pids?.firstWhereOrNull((e) => e != this.currentUserPidSnapshot());
    return pid;
  }

  //
  //
  //

  @nonVirtual
  bool? isUserAndUserRelationshipSnapshot() =>
      this.relationshipDefTypesSnapshot()?.contains(RelationshipDefType.USER_AND_USER);

  @nonVirtual
  bool? isUserAndJobRelationshipSnapshot() =>
      this.relationshipDefTypesSnapshot()?.contains(RelationshipDefType.USER_AND_JOB);

  @nonVirtual
  bool? isJobAndProjectRelationshipSnapshot() =>
      this.relationshipDefTypesSnapshot()?.contains(RelationshipDefType.JOB_AND_PROJECT);

  @nonVirtual
  bool? isProjectAndOrganizationRelationshipSnapshot() =>
      this.relationshipDefTypesSnapshot()?.contains(RelationshipDefType.PROJECT_AND_ORGANIZATION);

  @nonVirtual
  ModelRelationship? relationshipSnapshot() =>
      this.relationshipPoolSnapshot()?.firstWhereOrNull((e) => e.id == this.relationshipId);

  //
  //
  //

  @nonVirtual
  EventService? eventServiceSnapshot() => this
      .relationshipServiceSnapshot()
      ?.messageEventServices
      .pEventServicePool
      .value[this.relationshipId];
}
