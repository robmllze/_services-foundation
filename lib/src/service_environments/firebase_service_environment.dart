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

final class FirebaseServiceEnvironment extends ServiceEnvironment {
  //
  //
  //

  final FirebaseOptions firebaseOptions;

  //
  //
  //

  FirebaseServiceEnvironment._({
    required this.firebaseOptions,
    required FirebaseAuthServiceBroker authServiceBroker,
    required FirestoreServiceBroker databaseServiceBroker,
    required FirestoreQueryBroker databaseQueryBroker,
    required FirebaseFunctionsServiceBroker functionsServiceBroker,
    required FirebaseStorageServiceBroker fileServiceBroker,
    required FirebaseMessagingServiceBroker notificationServiceBroker,
  }) : super(
          authServiceBroker: authServiceBroker,
          databaseServiceBroker: databaseServiceBroker,
          databaseQueryBroker: databaseQueryBroker,
          functionsServiceBroker: functionsServiceBroker,
          fileServiceBroker: fileServiceBroker,
          notificationServiceBroker: notificationServiceBroker,
        );

  //
  //
  //

  static Future<ServiceEnvironment> create({
    required FirebaseOptions firebaseOptions,
    required String cloudMessagingVapidKey,
    required String functionsRegion,
    AuthServicePersistence persistence = AuthServicePersistence.INDEXED_DB,
  }) async {
    final firebaseApp = await Firebase.initializeApp(options: firebaseOptions);
    final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
    final firebaseAuth = FirebaseAuth.instanceFor(app: firebaseApp);

    await firebaseAuth.setPersistence(persistence.toFirebasePersistence());

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
      projectId: firebaseApp.options.projectId,
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
      functionsServiceBroker: functionsServiceBroker,
    );

    final serviceEnvironment = FirebaseServiceEnvironment._(
      firebaseOptions: firebaseOptions,
      authServiceBroker: authServiceBroker,
      databaseServiceBroker: databaseServiceBroker,
      databaseQueryBroker: databaseQueryBroker,
      functionsServiceBroker: functionsServiceBroker,
      fileServiceBroker: fileServiceBroker,
      notificationServiceBroker: notificationServiceBroker,
    );
    return serviceEnvironment;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _ToFirebasePersistence on AuthServicePersistence {
  Persistence toFirebasePersistence() {
    switch (this) {
      case AuthServicePersistence.INDEXED_DB:
        return Persistence.INDEXED_DB;
      case AuthServicePersistence.LOCAL:
        return Persistence.LOCAL;
      case AuthServicePersistence.NONE:
        return Persistence.NONE;
      case AuthServicePersistence.SESSION:
        return Persistence.SESSION;
    }
  }
}
