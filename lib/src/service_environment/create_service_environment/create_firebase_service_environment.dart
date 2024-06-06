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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Creates a service environment that mainly uses Firebase services.
Future<ServiceEnvironment> createFirebaseServiceEnvironment({
  required FirebaseOptions firebaseOptions,
  required String cloudMessagingVapidKey,
  required String functionsRegion,
}) async {
  final app = await Firebase.initializeApp(options: firebaseOptions);
  final firestore = FirebaseFirestore.instanceFor(app: app);
  final firebaseAuth = FirebaseAuth.instanceFor(app: app);
  final authServiceBroker = FirebaseAuthServiceBroker(
    firebaseAuth: firebaseAuth,
  );

  final databaseServiceBroker = FirestoreServiceBroker(
    firestore: firestore,
  );

  final databaseQueryBroker = FirestoreQueryBroker(
    databaseServiceBroker: databaseServiceBroker,
  );
  final functionsServiceBroker = FirebaseFunctionsServiceBroker(
    region: functionsRegion,
    projectId: firebaseOptions.projectId,
    authServiceBroker: authServiceBroker,
  );

  final firebaseStorage = FirebaseStorage.instance;

  final fileServiceBroker = FirebaseStorageServiceBroker(
    databaseServiceBroker: databaseServiceBroker,
    firebaseStorage: firebaseStorage,
  );

  final firebaseMessaging = FirebaseMessaging.instance;

  final notificationServiceBroker = FirebaseMessagingServiceBroker(
    firebaseMessaging: firebaseMessaging,
    cloudMessagingVapidKey: cloudMessagingVapidKey,
    databaseServiceBroker: databaseServiceBroker,
  );

  final serviceEnvironment = ServiceEnvironment(
    authServiceBroker: authServiceBroker,
    databaseServiceBroker: databaseServiceBroker,
    databaseQueryBroker: databaseQueryBroker,
    functionsServiceBroker: functionsServiceBroker,
    fileServiceBroker: fileServiceBroker,
    notificationServiceBroker: notificationServiceBroker,
  );
  return serviceEnvironment;
}
