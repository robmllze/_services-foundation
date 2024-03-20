//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// X|Y|Z & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import "package:flutter/material.dart" show StringCharacters;

import "/_common.dart";

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// final class FirebaseFirestoreQueryBroker extends DatabaseQueryInterface {
//   //
//   //
//   //

//   static final instance = FirebaseFirestoreQueryBroker._();

//   //
//   //
//   //

//   FirebaseFirestoreQueryBroker._();

//   //
//   //
//   //

//   @override
//   Future<Iterable<ModelUserPub>> queryUserPubsByNameOrEmail({
//     required DatabaseServiceInterface databaseService,
//     required String nameOrEmailQuery,
//     int limit = 10,
//   }) async {
//     final collection = (databaseService as FirebaseFirestoreServiceBroker)
//         // ignore: invalid_use_of_visible_for_testing_member
//         .firebaseFirestore
//         .collection(Schema.usersRef().collectionPath!);
//     // NB: Emails and searchable names must be lowercase for this function to work.
//     final searchableQuery = nameOrEmailQuery.toLowerCase();
//     // 0. Text length must be at least 2 to start the query.
//     if (searchableQuery.length > 2) {
//       // 1. Get the text with the last character incremented.
//       final b = searchableQuery.substring(0, searchableQuery.length - 1) +
//           String.fromCharCode(searchableQuery.characters.last.codeUnits[0] + 1);
//       // 2. Get all user models whose emails start with the inputted text [a].
//       final matchesEmail = await collection
//           // Where the email contains the query.
//           .where(
//             ModelUserPub.K_EMAIL_SEARCHABLE,
//             isGreaterThanOrEqualTo: searchableQuery,
//           )
//           .where(
//             ModelUserPub.K_EMAIL_SEARCHABLE,
//             isLessThan: b,
//           )
//           .orderBy(
//             ModelUserPub.K_EMAIL_SEARCHABLE,
//           )
//           .limit(limit)
//           .get();
//       // 3. Get all user models whose searchable names start with the inputted text [a].
//       final matchesDisplayName = await collection
//           // Where the searchable name contains the query.
//           .where(
//             ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
//             isGreaterThanOrEqualTo: searchableQuery,
//           )
//           .where(
//             ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
//             isLessThan: b,
//           )
//           .orderBy(
//             ModelUserPub.K_DISPLAY_NAME_SEARCHABLE,
//           )
//           .limit(limit)
//           .get();
//       // 4. Combine the results. NOTE: There may be duplicates.
//       final matchesCombined = [...matchesEmail.docs, ...matchesDisplayName.docs]
//           .map((final snapshot) => ModelUserPub.fromJson(snapshot.data()))
//           .toSet();
//       // 5. Get a unique set of all access UIDs.
//       final userpubIds = matchesCombined.map((e) => e.id).nonNulls.toSet();
//       // 6. Remove duplicates as well as current user's model.
//       final matchesDuplicatesRemoved =
//           userpubIds.map((id) => matchesCombined.firstWhere((e) => e.id == id));
//       try {
//         // 7. Filter the matches that are marked as deleted.
//         final matchesNotDeleted = matchesDuplicatesRemoved.where((e) => e.whenDeleted == null);
//         // 8. Return the results.
//         return matchesNotDeleted;
//       } catch (_) {}
//     }
//     // 8. No results.
//     return [];
//   }

//   //
//   //
//   //

//   @override
//   Stream<Iterable<ModelUserPub>> queryUserPubsById({
//     required DatabaseServiceInterface<Model> databaseService,
//     required Set<String> userpubIds,
//     int limit = 1000,
//   }) {
//     final collection = (databaseService as FirebaseFirestoreServiceBroker)
//         // ignore: invalid_use_of_visible_for_testing_member
//         .firebaseFirestore
//         .collection(Schema.userPubsRef().collectionPath!);
//     final userPub = collection
//         .where(ModelUserPub.K_ID, arrayContainsAny: userpubIds)
//         .limit(limit)
//         .snapshots()
//         .map((e) => e.docs.map((e) => ModelUserPub.fromJson(e.data())));
//     return userPub;
//   }

//   //
//   //
//   //

//   @override
//   Stream<Iterable<ModelRelationship>> queryRelationshipsForMembers({
//     required DatabaseServiceInterface<Model> databaseService,
//     required Set<String> memberIds,
//     int limit = 1000,
//   }) {
//     final collection = (databaseService as FirebaseFirestoreServiceBroker)
//         // ignore: invalid_use_of_visible_for_testing_member
//         .firebaseFirestore
//         .collection(Schema.relationshipsRef().collectionPath!);
//     final relationships = collection
//         .where(ModelRelationship.K_MEMBER_IDS, arrayContainsAny: memberIds)
//         .limit(limit)
//         .snapshots()
//         .map((e) => e.docs.map((e) => ModelRelationship.fromJson(e.data())));
//     return relationships;
//   }

//   //
//   //
//   //

//   @visibleForTesting
//   @override
//   Future<void> deleteCollectionTest({
//     required DatabaseServiceInterface<Model> databaseService,
//     required DataRef collectionRef,
//   }) async {
//     // ignore: invalid_use_of_visible_for_testing_member
//     final firebaseFirestore = (databaseService as FirebaseFirestoreServiceBroker).firebaseFirestore;
//     final batch = firebaseFirestore.batch();
//     final collection = firebaseFirestore.collection(collectionRef.collectionPath!);
//     final stream = collection.snapshots().asyncMap((e) async {
//       for (final doc in e.docs) {
//         batch.delete(doc.reference);
//       }
//     });
//     await streamToFuture(stream);
//     await batch.commit();
//   }
// }
