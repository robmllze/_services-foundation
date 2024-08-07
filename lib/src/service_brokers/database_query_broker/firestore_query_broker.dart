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
import 'package:flutter/material.dart' show StringCharacters;

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirestoreQueryBroker extends DatabaseQueryInterface {
  //
  //
  //

  const FirestoreQueryBroker({
    required FirestoreServiceBroker databaseServiceBroker,
  }) : super(databaseServiceBroker: databaseServiceBroker);

  //
  //
  //

  FirebaseFirestore get _firestore =>
      (this.databaseServiceBroker as FirestoreServiceBroker).firestore;

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByNameOrEmailQuery({
    required String partialNameOrEmail,
    int? limit = 10,
  }) {
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    // NB: Emails and searchable names must be lowercase for this function to work.
    final searchableQuery = partialNameOrEmail.toQueryable().queryableValueField;
    // Text length must be at least 2 to start the query.
    if (searchableQuery.length > 2) {
      // Get the text with the last character incremented.
      final b = searchableQuery.substring(0, searchableQuery.length - 1) +
          String.fromCharCode(searchableQuery.characters.last.codeUnits[0] + 1);
      // Get all user models whose emails start with the inputted text [a].
      const EMAIL_FIELD =
          '${ModelUserPubFieldNames.email}.${ModelQueryableFieldNames.queryableValue}';
      final stream1 = collection
          .baseQuery(limit: limit)
          // Where the email contains the query.
          .where(
            EMAIL_FIELD,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            EMAIL_FIELD,
            isLessThan: b,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
      // Get all user models whose searchable names start with the inputted text [a].
      const DISPLAY_NAME_FIELDS =
          '${ModelUserPubFieldNames.displayName}.${ModelQueryableFieldNames.queryableValue}';
      final stream2 = collection
          .baseQuery(limit: limit)
          // Where the searchable name contains the query.
          .where(
            DISPLAY_NAME_FIELDS,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            DISPLAY_NAME_FIELDS,
            isLessThan: b,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));

      final combinedStream = StreamZip([stream1, stream2]).map((e) {
        return e.reduce((a, b) {
          final c = [...a, ...b].where((e) => e.deletedGReg == null);
          final d = Model.removeDuplicateRefs(c);
          return d;
        }).toSet();
      });

      return combinedStream;
    }
    // No results.
    return const Stream.empty();
  }

  //
  //
  //

  @override
  Stream<Iterable<TModel>> streamByWhereInElements<TModel extends Model>({
    required Set<String> elementKeys,
    required Iterable<String> elements,
    required DataRef collectionRef,
    required TFromJsonOrNull<TModel> fromJsonOrNull,
  }) {
    final elementSet = elements.where((e) => e.isNotEmpty).toSet();
    if (elementSet.isEmpty) {
      return const Stream.empty();
    }
    final collectionPath = collectionRef.collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    var snapshots = collection.baseQuery(limit: elementSet.length);
    for (final elementKey in elementKeys) {
      snapshots = snapshots.where(elementKey, whereIn: elementSet);
    }
    final results = snapshots
        .snapshots()
        .map((e) => e.docs.map((e) => fromJsonOrNull(e.data())))
        .map((e) => e.where((e) => e != null).map((e) => e!));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMember({
    required Iterable<String> memberPids,
    Iterable<RelationshipType> types = const {},
    int? limit,
  }) async* {
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    // arrayContainsAny only supports 30 at a time.
    for (final batch in _createBatches(memberPids, 30)) {
      var relationships = collection
          .baseQuery(limit: limit)
          .where(ModelRelationshipFieldNames.memberPids, arrayContainsAny: batch.toSet())
          .snapshots()
          .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));

      if (types.isNotEmpty) {
        relationships = relationships.map(
          (e) => e.where(
            (e) => types.contains(e.type),
          ),
        );
      }

      await for (var rel in relationships) {
        yield rel;
      }
    }
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForEveryMember({
    required Iterable<String> memberPids,
    Iterable<RelationshipType> types = const {},
    int? limit,
  }) async* {
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);

    // arrayContains only supports 30 at a time.
    for (final batch in _createBatches(memberPids, 30)) {
      var relationships = collection
          .baseQuery(limit: limit)
          .where(ModelRelationshipFieldNames.memberPids, arrayContains: batch.toSet())
          .snapshots()
          .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));

      if (types.isNotEmpty) {
        relationships = relationships.map((e) => e.where((e) => types.contains(e.type)));
      }

      await for (var rel in relationships) {
        yield rel;
      }
    }
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> streamFilesByCreatorId({
    required Iterable<String> createdByAny,
    int? limit,
  }) async* {
    final collectionPath = Schema.filesRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    final FIELD =
        '${ModelFileEntryFieldNames.createdGReg}.${ModelRegistrationFieldNames.registeredBy}';

    // whereIn only supports 30 at a time.
    for (final batch in _createBatches(createdByAny, 30)) {
      final snapshots = collection
          .baseQuery(limit: limit)
          .where(
            FIELD,
            whereIn: batch.toSet(),
          )
          .snapshots();

      final results = snapshots.map((e) => e.docs.map((e) => ModelFileEntry.fromJson(e.data())));
      await for (var result in results) {
        yield result;
      }
    }
  }

  //
  //
  //

  @visibleForTesting
  @override
  Future<Iterable<BatchOperation>> getLazyDeleteCollectionOperations({
    required DataRef collectionRef,
  }) async {
    final result = <BatchOperation>[];
    final collectionPath = collectionRef.collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    final stream = collection.baseQuery().snapshots().asyncMap((e) async {
      for (final doc in e.docs) {
        final ref = collectionRef.copyWith(DataRefModel(id: doc.id));
        final operation = DeleteOperation(
          model: Model(
            {
              'ref': ref.toJson(),
            },
          ),
        );
        result.add(operation);
      }
    });
    await streamToFuture(stream);
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Iterable<Iterable<T>> _createBatches<T>(Iterable<T> source, int batchSize) sync* {
  var batch = <T>[];
  for (final item in source) {
    batch.add(item);
    if (batch.length == batchSize) {
      yield batch;
      batch = <T>[];
    }
  }
  if (batch.isNotEmpty) {
    yield batch;
  }
}
