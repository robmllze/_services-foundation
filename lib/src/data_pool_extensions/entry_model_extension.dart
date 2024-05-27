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

extension EntryModelPoolExtension<TModel extends EntryModel> on Iterable<TModel> {
  //
  //
  //

  // --- Sorting ---------------------------------------------------------------

  Iterable<TModel> byTitleAscending() {
    return this.toList()
      ..sort((e0, e1) {
        final t0 = e0.titleSearchable ?? e0.title ?? '';
        final t1 = e1.titleSearchable ?? e1.title ?? '';
        final n = t0.compareTo(t1);
        return n;
      });
  }

  //
  //
  //

  Iterable<TModel> byTitleDescending() {
    return this.byTitleAscending().toList().reversed;
  }

  //
  //
  //

  Iterable<TModel> byCreatedAtAscending() {
    return this.toList()
      ..sort((e0, e1) {
        final now = DateTime.now();
        final d0 = e0.createdAt ?? now;
        final d1 = e1.createdAt ?? now;
        final n = d0.compareTo(d1);
        return n;
      });
  }

  //
  //
  //

  Iterable<TModel> byCreatedAtDescending() {
    return this.byCreatedAtAscending().toList().reversed;
  }
}
