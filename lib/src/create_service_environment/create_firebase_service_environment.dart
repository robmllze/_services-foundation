//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:hive_flutter/hive_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Creates a service environment that mainly uses Firebase services.
Future<ServiceEnvironment> createFirebaseServiceEnvironment({
  required FirebaseOptions firebaseOptions,
  required String functionsRegion,
}) async {
  final app = await Firebase.initializeApp(options: firebaseOptions);
  final firebaseFirestore = FirebaseFirestore.instanceFor(app: app);
  final firebaseAuth = FirebaseAuth.instanceFor(app: app);
  final authServiceBroker = FirebaseAuthServiceBroker(
    firebaseAuth: firebaseAuth,
  );
  final databaseServiceBroker = FirebaseFirestoreServiceBroker(
    firebaseFirestore: firebaseFirestore,
  );

  await Hive.initFlutter();
  final localDatabaseServiceBroker = HiveServiceBroker();

  final databaseQueryBroker = FirebaseFirestoreQueryBroker(
    firebaseFirestore: firebaseFirestore,
  );
  final functionsServiceBroker = FirebaseFunctionsServiceBroker(
    region: functionsRegion,
    projectId: firebaseOptions.projectId,
    authServiceBroker: authServiceBroker,
  );

  const fieldValueBroker = FirebaseFieldValueBroker.instance;
  final firebaseStorage = FirebaseStorage.instance;

  final fileServiceBroker = FirebaseStorageServiceBroker(
    databaseServiceBroker: databaseServiceBroker,
    fieldValueBroker: fieldValueBroker,
    firebaseStorage: firebaseStorage,
  );
  final serviceEnvironment = ServiceEnvironment(
    authServiceBroker: authServiceBroker,
    databaseServiceBroker: databaseServiceBroker,
    localDatabaseServiceBroker: localDatabaseServiceBroker,
    databaseQueryBroker: databaseQueryBroker,
    functionsServiceBroker: functionsServiceBroker,
    fileServiceBroker: fileServiceBroker,
    fieldValueBroker: fieldValueBroker,
  );
  return serviceEnvironment;
}
