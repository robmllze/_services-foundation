//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Creates a service environment that mainly uses Hive.
@visibleForTesting
Future<ServiceEnvironment> createHiveServiceEnvironment() async {
  final databaseServiceBroker = await HiveServiceBroker.initFlutter();
  final databaseQueryBroker = HiveQueryBroker(databaseServiceBroker: databaseServiceBroker);

  final authServiceBroker = HiveAuthServiceBroker(
    sessionKey: 'session',
    hiveServiceBroker: databaseServiceBroker,
  );

  final functionsServiceBroker = NoFunctionsServiceBroker(
    region: '',
    projectId: '',
    authServiceBroker: authServiceBroker,
  );

  final fileServiceBroker = HiveStorageServiceBroker(
    hiveServiceBroker: databaseServiceBroker,
  );
  final serviceEnvironment = ServiceEnvironment(
    authServiceBroker: authServiceBroker,
    databaseServiceBroker: databaseServiceBroker,
    databaseQueryBroker: databaseQueryBroker,
    functionsServiceBroker: functionsServiceBroker,
    fileServiceBroker: fileServiceBroker,
  );
  return serviceEnvironment;
}
