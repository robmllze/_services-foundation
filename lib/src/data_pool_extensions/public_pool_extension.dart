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

extension PublicPoolExtension<TModel extends PublicModel> on Iterable<TModel> {
  //
  //
  //

  // --- Sorting ---------------------------------------------------------------

  Iterable<TModel> byDisplayNameAscending() {
    return this.toList()
      ..sort((e0, e1) {
        final t0 = e0.displayNameSearchable ?? e0.displayName ?? '';
        final t1 = e1.displayNameSearchable ?? e1.displayName ?? '';
        final n = t0.compareTo(t1);
        return n;
      });
  }

  //
  //
  //

  Iterable<TModel> byDisplayNameDescending() {
    return byDisplayNameAscending().toList().reversed;
  }

  // --- Filtering -------------------------------------------------------------

  Iterable<TModel> filterByPartialNameOrEmail({
    required String partialNameOrEmail,
  }) {
    return this
        .filterByPartialEmail(partialEmail: partialNameOrEmail)
        .filterByPartialName(partialName: partialNameOrEmail);
  }

  //
  //
  //

  Iterable<TModel> filterByPartialName({
    required String partialName,
  }) {
    final query = partialName.toLowerCase();
    final results = this.where((user) {
      final name = (user.displayNameSearchable ?? user.displayName)?.toLowerCase();
      final cases = [
        if (name != null) ...[
          name.contains(query),
          query.contains(name),
        ],
      ];
      return cases.contains(true);
    });
    return results;
  }

  //
  //
  //

  Iterable<TModel> filterByPartialEmail({
    required String partialEmail,
  }) {
    final query = partialEmail.toLowerCase();
    final results = this.where((user) {
      final email = user.email;
      final cases = [
        if (email != null) ...[
          email.contains(query),
          query.contains(email),
        ],
      ];
      return cases.contains(true);
    });
    return results;
  }

  //
  //
  //

  Iterable<TModel> filterByRelationship({
    required String relationshipId,
    required Iterable<ModelRelationship> relationshipPool,
    required Iterable<String> memberPidPrefixes,
  }) {
    final relationship = relationshipPool.firstWhereOrNull((e) => e.id == relationshipId);
    if (relationship != null) {
      final pids = relationship.extractMemberPids(
        memberPidPrefixes: memberPidPrefixes,
      );
      final result = pids.map((pid) => this.firstWhereOrNull((e) => e.id == pid)).nonNulls;
      return result;
    } else {
      return [];
    }
  }
}
