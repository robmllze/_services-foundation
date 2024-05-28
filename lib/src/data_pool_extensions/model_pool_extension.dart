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

extension ModelPoolExtension<TModel extends Model> on Iterable<TModel> {
  //
  //
  //

  // --- Utils -----------------------------------------------------------------

  Set<String> allIds() => this.map((e) => e.id).nonNulls.toSet();

  Set<DataRef> allDataRefs() => this.map((e) => e.ref).nonNulls.toSet();

  // --- Filtering -------------------------------------------------------------

  Iterable<TModel> queryByWhereInElements({
    required Set<String> elementKeys,
    required Iterable<String> elements,
    required TFromJsonOrNull<TModel> fromJsonOrNull,
  }) {
    final results = this
        .where((model) {
          final data = model.toJson();
          for (final entry in data.entries) {
            final key = entry.key;
            final value = entry.value;
            if (elements.contains(key)) {
              if (value is Iterable) {
                if (value.any(elementKeys.contains)) {
                  return true;
                }
              }
            }
          }
          return false;
        })
        .map((e) => fromJsonOrNull(e.toJson()))
        .nonNulls;
    return results;
  }
}
