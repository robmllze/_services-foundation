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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show StringCharacters;

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirebaseFirestoreQueryBroker extends _StreamByPids {
  //
  //
  //

  static final instance = FirebaseFirestoreQueryBroker._();

  //
  //
  //

  FirebaseFirestoreQueryBroker._();

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByPids({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final snapshots =
        collection.limit(pids.length).where(ModelUserPub.K_ID, arrayContainsAny: pids).snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  @override
  Stream<Iterable<ModelUserPub>> queryUserPubsByNameOrEmail({
    required DatabaseServiceInterface databaseServiceBroker,
    required String nameOrEmailQuery,
    int limit = 10,
  }) {
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
          return [...a, ...b].where((e) => e.deletedAt == null);
        }).toSet();
      });

      try {
        // 7. Filter the matches that are marked as deleted.
        final matchesNotDeleted = matchesDuplicatesRemoved.where((e) => e.deletedAt == null);
        // 8. Return the results.
        return matchesNotDeleted;
      } catch (_) {}
    }
    // 8. No results.
    return [];
  }

  @override
  Stream<Iterable<ModelUserPub>> streamUserPubsByEmail({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> emails,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final searchableEmails = emails.map((e) => e.toLowerCase());
    final results = collection
        .limit(emails.length)
        .where(ModelUserPub.K_EMAIL_SEARCHABLE, arrayContainsAny: searchableEmails)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  // Relationships.
  //

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAnyMembers({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> memberPids,
    int maxRelationshipsPerMember = 10,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final limit = memberPids.length * maxRelationshipsPerMember;
    final relationships = collection
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContainsAny: memberPids)
        .limit(limit)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));
    return relationships;
  }

  @override
  Stream<Iterable<ModelRelationship>> streamRelationshipsForAllMembers({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> memberPids,
    int maxRelationshipsPerMember = 10,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.relationshipsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final limit = memberPids.length * maxRelationshipsPerMember;
    final relationships = collection
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContains: memberPids)
        .limit(limit)
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
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract final class _StreamByPids extends DatabaseQueryInterface {
  //
  //
  //

  Stream<Iterable<ModelOrganization>> streamOrganizationsByPids({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.organizationsRef().collectionPath!;
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pids.length)
        .where(
          ModelOrganization.K_PID,
          arrayContainsAny: pids,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelOrganization.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  Stream<Iterable<ModelProject>> streamProjectsByPids({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.projectsRef().collectionPath!;
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pids.length)
        .where(
          ModelProject.K_PID,
          arrayContainsAny: pids,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelProject.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  Stream<Iterable<ModelJob>> streamJobsByPids({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.jobsRef().collectionPath!;
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pids.length)
        .where(
          ModelJob.K_PID,
          arrayContainsAny: pids,
        )
        .snapshots();

    final results = snapshots.map((e) => e.docs.map((e) => ModelJob.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  Stream<Iterable<ModelUser>> streamUsersByPids({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.usersRef().collectionPath!;
    final snapshots = firebaseFirestore
        .collection(collectionPath)
        .limit(pids.length)
        .where(
          ModelJob.K_PID,
          arrayContainsAny: pids,
        )
        .snapshots();
    final results = snapshots.map((e) => e.docs.map((e) => ModelUser.fromJson(e.data())));
    return results;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _FirebaseFirestoreOnDatabaseServiceInterfaceExtension on DatabaseServiceInterface {
  FirebaseFirestore get firebaseFirestore =>
      (this as FirebaseFirestoreServiceBroker).firebaseFirestore;
}
