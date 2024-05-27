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

final class HiveQueryBroker extends DatabaseQueryInterface {
  //
  //
  //

  const HiveQueryBroker({
    required HiveServiceBroker databaseServiceBroker,
  }) : super(databaseServiceBroker: databaseServiceBroker);

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByNameOrEmailQuery({
    required String nameOrEmailQuery,
    int? limit = 10,
  }) {
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Stream<Iterable<T>> streamByWhereInElements<T>({
    required Iterable<String> elements,
    required DataRef collectionRef,
    required T? Function(Map<String, dynamic>? otherData) fromJsonOrNull,
    required Set<String> elementKeys,
  }) {
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMembers({
    required Iterable<String> pids,
    int? limit,
    Iterable<RelationshipDefType> defTypes = const {},
  }) {
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAllMembers({
    required Iterable<String> pids,
    int? limit,
    Iterable<RelationshipDefType> defTypes = const {},
  }) {
    throw UnimplementedError();
  }

  //
  //
  //

  @visibleForTesting
  @override
  Future<Iterable<BatchOperation>> getLazyDeleteCollectionOperations({
    required DataRef collectionRef,
  }) async {
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> streamFilesByCreatorId({
    required Iterable<String> createdByAny,
    int? limit,
  }) {
    throw UnimplementedError();
  }
}
