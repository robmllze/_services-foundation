//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:cloud_firestore/cloud_firestore.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension BaseQueryOnCollectionReferenceExtension<T> on CollectionReference<T> {
  Query<T> baseQuery({
    Object? ascendByField,
    Object? descendByField,
    int? limit,
  }) {
    return _baseQuery(
      this,
      ascendByField: ascendByField,
      descendByField: descendByField,
      limit: limit,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Query<T> _baseQuery<T>(
  CollectionReference<T> collection, {
  Object? ascendByField,
  Object? descendByField,
  int? limit,
}) {
  Query<T> query = collection;
  if (ascendByField != null) {
    query = query.orderBy(ascendByField);
  }
  if (descendByField != null) {
    query = query.orderBy(descendByField, descending: true);
  }
  if (limit != null && limit > 0) {
    query = query.limit(limit);
  }
  return query;
}
