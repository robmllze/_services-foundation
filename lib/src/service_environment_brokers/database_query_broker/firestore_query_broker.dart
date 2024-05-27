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
    final searchableQuery = partialNameOrEmail.toLowerCase();
    // Text length must be at least 2 to start the query.
    if (searchableQuery.length > 2) {
      // Get the text with the last character incremented.
      final b = searchableQuery.substring(0, searchableQuery.length - 1) +
          String.fromCharCode(searchableQuery.characters.last.codeUnits[0] + 1);
      // Get all user models whose emails start with the inputted text [a].
      final stream1 = collection
          .baseQuery(limit: limit)
          // Where the email contains the query.
          .where(
            ModelUserPub.K_EMAIL,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            ModelUserPub.K_EMAIL,
            isLessThan: b,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
      // Get all user models whose searchable names start with the inputted text [a].
      final stream2 = collection
          .baseQuery(limit: limit)
          // Where the searchable name contains the query.
          .where(
            ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
            isLessThan: b,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));

      final combinedStream = StreamZip([stream1, stream2]).map((e) {
        return e.reduce((a, b) {
          final c = [...a, ...b].where((e) => e.deletedAt == null);
          final d = Model.removeDuplicateIds(c);
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
    required TModel? Function(Map<String, dynamic>? otherData) fromJsonOrNull,
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
    Iterable<RelationshipDefType> defTypes = const {},
    int? limit,
  }) {
    var pidSet = memberPids.toSet();
    if (pidSet.length > 30) {
      Here().debugLogError('arrayContainsAny only supports up to 30 values.');
      pidSet = pidSet.take(30).toSet();
    }
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    var relationships = collection
        .baseQuery(limit: limit)
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContainsAny: pidSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));

    if (defTypes.isNotEmpty) {
      relationships = relationships.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return relationships;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForEveryMember({
    required Iterable<String> memberPids,
    Iterable<RelationshipDefType> defTypes = const {},
    int? limit,
  }) {
    var pidSet = memberPids.toSet();
    if (pidSet.length > 30) {
      Here().debugLogError('arrayContains only supports up to 30 values.');
      pidSet = pidSet.take(30).toSet();
    }
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    var relationships = collection
        .baseQuery(limit: limit)
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContains: pidSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));
    if (defTypes.isNotEmpty) {
      relationships = relationships.map((e) => e.where((e) => defTypes.contains(e.defType)));
    }
    return relationships;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelFileEntry>> streamFilesByCreatorId({
    required Iterable<String> createdByAny,
    int? limit,
  }) {
    var createdByAnySet = createdByAny.toSet();
    if (createdByAnySet.length > 30) {
      Here().debugLogError('whereIn only supports up to 30 values.');
      createdByAnySet = createdByAnySet.take(30).toSet();
    }
    final collectionPath = Schema.filesRef().collectionPath!;
    final collection = this._firestore.collection(collectionPath);
    final snapshots = collection
        .baseQuery(limit: limit)
        .where(
          ModelFileEntry.K_CREATED_BY,
          whereIn: createdByAny,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelFileEntry.fromJson(e.data())));
    return results;
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
        final ref = (collectionRef..id = doc.id);
        final operation = DeleteOperation(
          model: DataModel(
            data: {
              Model.K_REF: ref.toJson(),
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
