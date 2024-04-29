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

  static final instance = FirebaseFirestoreQueryBroker._();

  //
  //
  //

  FirebaseFirestoreQueryBroker._();

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByNameOrEmailQuery({
    required DatabaseServiceInterface databaseServiceBroker,
    required String nameOrEmailQuery,
    int limit = 10,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
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
      final stream1 = collection
          .positiveLimit(limit)
          // Where the email contains the query.
          .where(
            ModelUserPub.K_EMAIL_SEARCHABLE,
            isGreaterThanOrEqualTo: searchableQuery,
          )
          .where(
            ModelUserPub.K_EMAIL_SEARCHABLE,
            isLessThan: b,
          )
          .orderBy(
            ModelUserPub.K_EMAIL_SEARCHABLE,
          )
          .snapshots()
          .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
      // Get all user models whose searchable names start with the inputted text [a].
      final stream2 = collection
          .positiveLimit(limit)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = collection
        .positiveLimit(pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> emails,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final emailSet = emails.nullIfEmpty?.map((e) => e.toLowerCase()).toSet();
    final results = collection
        .positiveLimit(emailSet?.length)
        .where(ModelUserPub.K_EMAIL_SEARCHABLE, whereIn: emailSet)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMembers({
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
    int? limit,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final relationships = collection
        .positiveLimit(limit ?? pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
    int? limit,
  }) {
    final firebaseFirestore =
        (databaseServiceBroker as FirebaseFirestoreServiceBroker).firebaseFirestore;
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final pidSet = pids.nullIfEmpty?.toSet();
    final relationships = collection
        .positiveLimit(limit ?? pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required DataRef collectionRef,
  }) async {
    final result = <BatchOperation>[];
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = collectionRef.collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final stream = collection.snapshots().asyncMap((e) async {
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.usersRef().collectionPath!;
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .positiveLimit(pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.organizationsRef().collectionPath!;
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .positiveLimit(pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.projectsRef().collectionPath!;
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .positiveLimit(pidSet?.length)
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
    required DatabaseServiceInterface databaseServiceBroker,
    required Iterable<String> pids,
  }) {
    databaseServiceBroker as FirebaseFirestoreServiceBroker;
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.jobsRef().collectionPath!;
    final pidSet = pids.nullIfEmpty?.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .positiveLimit(pidSet?.length)
        .where(
          ModelJob.K_PID,
          whereIn: pidSet,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelJob.fromJson(e.data())));
    return results;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _PositiveLimit<A> on CollectionReference<A> {
  Query<A> positiveLimit(
    int? l, {
    int fallback = 10000,
  }) {
    return this.limit(
      l != null
          ? l < 1
              ? fallback
              : l
          : fallback,
    );
  }
}
