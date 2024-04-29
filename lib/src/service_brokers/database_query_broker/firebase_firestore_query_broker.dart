//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:async/async.dart' show StreamZip;

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
    // 0. Text length must be at least 2 to start the query.
    if (searchableQuery.length > 2) {
      // 1. Get the text with the last character incremented.
      final b = searchableQuery.substring(0, searchableQuery.length - 1) +
          String.fromCharCode(searchableQuery.characters.last.codeUnits[0] + 1);
      // 2. Get all user models whose emails start with the inputted text [a].
      final stream1 = collection
          .limit(limit)
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
      // 3. Get all user models whose searchable names start with the inputted text [a].
      final stream2 = collection
          .limit(limit)
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
    // 8. No results.
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
    final pidSet = pids.toSet();
    final snapshots = collection
        .limit(pidSet.length)
        .where(ModelUserPub.K_ID, arrayContainsAny: pidSet)
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
    final emailSet = emails.toSet();
    final searchableEmails = emailSet.map((e) => e.toLowerCase());
    final results = collection
        .limit(emailSet.length)
        .where(ModelUserPub.K_EMAIL_SEARCHABLE, arrayContainsAny: searchableEmails)
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
    final pidSet = pids.toSet();
    final relationships = collection
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContainsAny: pidSet)
        .limit(limit ?? pidSet.length)
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
    final pidSet = pids.toSet();
    final relationships = collection
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContains: pidSet)
        .limit(limit ?? pidSet.length)
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
    final pidSet = pids.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pidSet.length)
        .where(
          ModelJob.K_PID,
          arrayContainsAny: pidSet,
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
    final pidSet = pids.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pidSet.length)
        .where(
          ModelOrganization.K_PID,
          arrayContainsAny: pidSet,
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
    final pidSet = pids.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pidSet.length)
        .where(
          ModelProject.K_PID,
          arrayContainsAny: pidSet,
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
    final pidSet = pids.toSet();
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pidSet.length)
        .where(
          ModelJob.K_PID,
          arrayContainsAny: pidSet,
        )
        .snapshots();

    final results = snapshots.map((e) => e.docs.map((e) => ModelJob.fromJson(e.data())));
    return results;
  }
}
