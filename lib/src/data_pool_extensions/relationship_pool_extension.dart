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

extension RelationshipPoolExtension on Iterable<ModelRelationship> {
  //
  //
  //

  // --- Sorting ---------------------------------------------------------------

  // --- Filtering -------------------------------------------------------------

  Iterable<ModelRelationship> filterByDefType({
    required Iterable<RelationshipDefType> defTypes,
  }) {
    if (defTypes.isEmpty) return [];
    return this.where(
      (rel) {
        final defType = rel.defType;
        return defType != null ? defTypes.contains(defType) : false;
      },
    );
  }

  //
  //
  //

  Iterable<ModelRelationship> filterByEveryMember({
    required Iterable<String> memberPids,
  }) {
    if (memberPids.isEmpty) return [];
    return this.where(
      (rel) {
        return memberPids.every((pid) {
          return rel.memberPids?.contains(pid) == true;
        });
      },
    );
  }

  //
  //
  //

  Iterable<ModelRelationship> filterByAnyMember({
    required Iterable<String> memberPids,
  }) {
    if (memberPids.isEmpty) return [];
    return this.where(
      (rel) {
        return memberPids.any((pid) {
          return rel.memberPids?.contains(pid) == true;
        });
      },
    );
  }

  //
  //
  //

  Iterable<String> allMemberPids() {
    return this.map((rel) => rel.memberPids ?? {}).tryReduce((a, b) => {...a, ...b})?.toSet() ?? {};
  }

  //
  //
  //

  Iterable<String> allIds() {
    return this.map((e) => e.id).nonNulls.toSet();
  }
}
