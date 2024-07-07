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

@visibleForTesting
final class HiveQueryBroker extends DatabaseQueryInterface {
  //
  //
  //

  const HiveQueryBroker({
    // ignore: invalid_use_of_visible_for_testing_member
    required HiveServiceBroker databaseServiceBroker,
  }) : super(databaseServiceBroker: databaseServiceBroker);

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByNameOrEmailQuery({
    required String partialNameOrEmail,
    int? limit = 10,
  }) {
    var stream = this.databaseServiceBroker.streamModelCollection(
          Schema.userPubsRef(),
          ModelUserPub.fromJsonOrNull,
        );
    stream = stream.map((e) {
      return e.filterByPartialNameOrEmail(partialNameOrEmail: partialNameOrEmail);
    });
    if (limit != null) {
      stream = stream.map((e) => e.take(limit));
    }
    return stream;
  }

  //
  //
  //

  @override
  Stream<Iterable<TModel>> streamByWhereInElements<TModel extends Model>({
    required Iterable<String> elements,
    required DataRef collectionRef,
    required TFromJsonOrNull<TModel> fromJsonOrNull,
    required Set<String> elementKeys,
  }) {
    var stream = this.databaseServiceBroker.streamModelCollection(
          collectionRef,
          fromJsonOrNull,
        );
    stream = stream.map((e) {
      return e.nonNulls.queryByWhereInElements(
        elementKeys: elementKeys,
        elements: elements,
        fromJsonOrNull: fromJsonOrNull,
      );
    });
    return stream;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMember({
    required Iterable<String> memberPids,
    Iterable<RelationshipType> types = const {},
    int? limit,
  }) {
    var stream = this.databaseServiceBroker.streamModelCollection(
          Schema.relationshipsRef(),
          ModelRelationship.fromJsonOrNull,
        );
    stream = stream.map((e) {
      return e.filterByAnyMember(memberPids: memberPids).filterByDefType(types: types);
    });
    if (limit != null) {
      stream = stream.map((e) => e.take(limit));
    }
    return stream;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForEveryMember({
    required Iterable<String> memberPids,
    Iterable<RelationshipType> types = const {},
    int? limit,
  }) {
    var stream = this.databaseServiceBroker.streamModelCollection(
          Schema.relationshipsRef(),
          ModelRelationship.fromJsonOrNull,
        );
    stream = stream.map((e) {
      return e.filterByEveryMember(memberPids: memberPids).filterByDefType(types: types);
    });
    if (limit != null) {
      stream = stream.map((e) => e.take(limit));
    }
    return stream;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> streamFilesByCreatorId({
    required Iterable<String> createdByAny,
    int? limit,
  }) {
    var stream = this.databaseServiceBroker.streamModelCollection(
          Schema.filesRef(),
          ModelFileEntry.fromJsonOrNull,
        );
    stream = stream.map((e) {
      return e.where((e) => createdByAny.contains(e.createdReg?.registeredBy));
    });
    if (limit != null) {
      stream = stream.map((e) => e.take(limit));
    }
    return stream;
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
}
