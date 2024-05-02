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

final class FirebaseFirestoreQueryBroker extends DatabaseQueryInterface {
  //
  //
  //

  final FirebaseFirestore firebaseFirestore;

  //
  //
  //

  FirebaseFirestoreQueryBroker({
    required this.firebaseFirestore,
  });

  //
  //
  //

  @override
  Stream<GenericModel?> streamModel(
    DataRef ref, [
    Future<void> Function(GenericModel? update)? onUpdate,
  ]) {
    final docRef = this.firebaseFirestore.doc(ref.docPath);
    return docRef.snapshots().asyncMap((snapshot) async {
      final modelData = snapshot.data();
      final model = modelData != null ? GenericModel(data: modelData) : null;
      await onUpdate?.call(model);
      return model;
    });
  }

  //
  //
  //

  @override
  Stream<Iterable<GenericModel>> streamModelCollection(
    DataRef ref, {
    Future<void> Function(Iterable<GenericModel> update)? onUpdate,
    Object? ascendByField,
    Object? descendByField,
    int? limit,
  }) {
    final collection = this.firebaseFirestore.collection(ref.collectionPath!);
    final snapshots = _getBaseQuery(
      collection,
      ascendByField: ascendByField,
      descendByField: descendByField,
      limit: limit,
    ).snapshots();
    final result = snapshots.asyncMap((querySnapshot) async {
      final modelsData = querySnapshot.docs.map((e) => e.data());
      final models = modelsData.map((modelData) => GenericModel(data: modelData));
      await onUpdate?.call(models);
      return models;
    });
    return result;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByNameOrEmailQuery({
    required String nameOrEmailQuery,
    int? limit = 10,
  }) {
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    // NB: Emails and searchable names must be lowercase for this function to work.
    final searchableQuery = nameOrEmailQuery.toLowerCase();
    // Text length must be at least 2 to start the query.
    if (searchableQuery.length > 2) {
      // Get the text with the last character incremented.
      final b = searchableQuery.substring(0, searchableQuery.length - 1) +
          String.fromCharCode(searchableQuery.characters.last.codeUnits[0] + 1);
      // Get all user models whose emails start with the inputted text [a].

      final stream1 = _getBaseQuery(collection, limit: limit)
          // Where the email contains the query.
          .where(
            ModelUserPub.K_EMAIL,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            ModelUserPub.K_EMAIL,
            isLessThan: b,
          )
          .orderBy(
            ModelUserPub.K_EMAIL,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
      // Get all user models whose searchable names start with the inputted text [a].
      final stream2 = _getBaseQuery(collection, limit: limit)
          // Where the searchable name contains the query.
          .where(
            ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
            isLessThan: b,
          )
          .orderBy(
            ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
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
  Stream<Iterable<ModelUserPub>> streamUserPubsByPids({
    required Iterable<String> pids,
  }) {
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = _getBaseQuery(collection, limit: pidSet?.length)
        .where(ModelUserPub.K_ID, whereIn: pidSet)
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByEmails({
    required Iterable<String> emails,
  }) {
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final emailSet = emails.nullIfEmpty?.map((e) => e.toLowerCase()).toSet();
    final results = _getBaseQuery(collection, limit: emailSet?.length)
        .where(ModelUserPub.K_EMAIL, whereIn: emailSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMembers({
    required Iterable<String> pids,
    int? limit,
  }) {
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final relationships = _getBaseQuery(collection, limit: limit)
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContainsAny: pidSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));
    return relationships;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAllMembers({
    required Iterable<String> pids,
    int? limit,
  }) {
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final relationships = _getBaseQuery(collection, limit: limit)
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContains: pidSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));
    return relationships;
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
    final collection = this.firebaseFirestore.collection(collectionPath);
    final stream = _getBaseQuery(collection).snapshots().asyncMap((e) async {
      for (final doc in e.docs) {
        result.add(DeleteOperation(ref: collectionRef.copyWith(id: doc.id)));
      }
    });
    await streamToFuture(stream);
    return result;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelUser>> streamUsersByPids({
    required Iterable<String> pids,
  }) {
    final collectionPath = Schema.usersRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = _getBaseQuery(collection, limit: pidSet?.length)
        .where(
          ModelJob.K_PID,
          whereIn: pidSet,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelUser.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelOrganization>> streamOrganizationsByPids({
    required Iterable<String> pids,
  }) {
    final collectionPath = Schema.organizationsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = _getBaseQuery(collection, limit: pidSet?.length)
        .where(
          ModelOrganization.K_PID,
          whereIn: pidSet,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelOrganization.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelProject>> streamProjectsByPids({
    required Iterable<String> pids,
  }) {
    final collectionPath = Schema.projectsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = _getBaseQuery(collection, limit: pidSet?.length)
        .where(
          ModelProject.K_PID,
          whereIn: pidSet,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelProject.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelJob>> streamJobsByPids({
    required Iterable<String> pids,
  }) {
    final collectionPath = Schema.jobsRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = _getBaseQuery(collection, limit: pidSet?.length)
        .where(
          ModelJob.K_PID,
          whereIn: pidSet,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelJob.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelMediaEntry>> streamMediaByCreatorId({
    required Set<String> createdByAny,
    int? limit,
  }) {
    final collectionPath = Schema.mediaRef().collectionPath!;
    final collection = this.firebaseFirestore.collection(collectionPath);
    final snapshots = _getBaseQuery(collection, limit: limit)
        .where(
          ModelMediaEntry.K_CREATED_BY,
          whereIn: createdByAny,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelMediaEntry.fromJson(e.data())));
    return results;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Query<T> _getBaseQuery<T>(
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
