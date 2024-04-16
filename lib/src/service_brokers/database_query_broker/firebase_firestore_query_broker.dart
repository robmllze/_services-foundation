//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart' show StringCharacters;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<Iterable<ModelUserPub>> queryUserPubsByNameOrEmail({
    required DatabaseServiceInterface databaseServiceBroker,
    required String nameOrEmailQuery,
    int limit = 10,
  }) async {
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
      final matchesEmail = await collection
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
          .limit(limit)
          .get();
      // 3. Get all user models whose searchable names start with the inputted text [a].
      final matchesDisplayName = await collection
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
          .limit(limit)
          .get();
      // 4. Combine the results. NOTE: There may be duplicates.
      final matchesCombined = [...matchesEmail.docs, ...matchesDisplayName.docs]
          .map((final snapshot) => ModelUserPub.fromJson(snapshot.data()))
          .toSet();
      // 5. Get a unique set of all access UIDs.
      final userpids = matchesCombined.map((e) => e.id).nonNulls.toSet();
      // 6. Remove duplicates as well as current user's model.
      final matchesDuplicatesRemoved =
          userpids.map((id) => matchesCombined.firstWhere((e) => e.id == id));
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

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> queryUserPubsByEmail({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> emails,
    int limit = 1000,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final searchableEmails = emails.map((e) => e.toLowerCase());
    final results = collection
        .where(ModelUserPub.K_EMAIL_SEARCHABLE, arrayContainsAny: searchableEmails)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelUserPub>> queryUserPubsById({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> pids,
    int limit = 1000,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collectionPath = Schema.userPubsRef().collectionPath!;
    final collection = firebaseFirestore.collection(collectionPath);
    final results = collection
        .where(ModelUserPub.K_ID, arrayContainsAny: pids)
        .limit(limit)
        .snapshots()
        .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
    return results;
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> queryRelationshipsForMembers({
    required DatabaseServiceInterface databaseServiceBroker,
    required Set<String> memberPids,
    int limit = 1000,
  }) {
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collection = firebaseFirestore.collection(Schema.relationshipsRef().collectionPath!);
    final relationships = collection
        .where(ModelRelationship.K_MEMBER_PIDS, arrayContainsAny: memberPids)
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
  Future<Iterable<BatchWriteOperation>> getLazyDeleteCollectionOperations({
    required DatabaseServiceInterface databaseServiceBroker,
    required DataRef collectionRef,
  }) async {
    final result = <BatchWriteOperation>[];
    final firebaseFirestore = databaseServiceBroker.firebaseFirestore;
    final collection = firebaseFirestore.collection(collectionRef.collectionPath!);
    final stream = collection.snapshots().asyncMap((e) async {
      for (final doc in e.docs) {
        doc.reference.id;
        final ref = collectionRef.copyWith(id: doc.id);
        result.add(BatchWriteOperation(ref, delete: true));
      }
    });
    await streamToFuture(stream);
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _FirebaseFirestoreOnDatabaseServiceInterfaceExtension on DatabaseServiceInterface {
  FirebaseFirestore get firebaseFirestore =>
      (this as FirebaseFirestoreServiceBroker).firebaseFirestore;
}
