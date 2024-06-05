//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:firebase_messaging/firebase_messaging.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirebaseMessagingServiceBroker extends NotificationServiceInterface {
  //
  //
  //

  final FirebaseMessaging firebaseMessaging;
  final String cloudMessagingVapidKey;
  final DatabaseServiceInterface databaseServiceBroker;

  //
  //
  //

  FirebaseMessagingServiceBroker({
    required this.firebaseMessaging,
    required this.cloudMessagingVapidKey,
    required this.databaseServiceBroker,
  }) {
    () async {
      await this.firebaseMessaging.setAutoInitEnabled(true);
      await this.firebaseMessaging.requestPermission();
    }();
  }

  //
  //
  //

  @override
  Future<void> send({
    required String title,
    required String body,
    required String topic,
    required Map<String, dynamic> data,
  }) async {}

  //
  //
  //

  @override
  void onRegistered(ModelAppRegistration registration) {
    // TODO: Perhaps we want to update some pod here or something.
  }

  //
  //
  //

  @override
  Future<void> register({required String currentUserPid}) async {
    final temp = await this.getNewRegistration();
    if (temp != null) {
      ModelAppRegistration? registration;
      await this.databaseServiceBroker.runTransaction((transaction) async {
        // Get the current ModelUserPub.
        final ref = Schema.userPubsRef(userPid: currentUserPid);
        final model = (await transaction.read(ref, ModelUserPub.fromJsonOrNull))!;

        // 0. Get all unique entries.
        final e0 = model.appRegistrations?.entries.unique() ?? [];

        // 1. Get all entries with the same ipAddress or notificationToken.
        final e1 = e0.where((e) {
          return e.value.ipAddress == temp.ipAddress ||
              e.value.notificationToken == temp.notificationToken;
        });

        final update = ((e1.toList()
                  ..sort((a, b) => a.value.createdAtField.compareTo(b.value.createdAtField)))
                .lastOrNull
              ?..value.loggedAt = DateTime.now()) ??
            MapEntry(temp.createdAt!, temp);

        // 2. Get all entries with a different ipAddress and notificationToken.
        final e2 = e0.where((e) {
          return e.value.ipAddress != temp.ipAddress &&
              e.value.notificationToken != temp.notificationToken;
        });

        // Update the model.
        model.appRegistrations = Map.fromEntries([...e2, update!]);

        // Overwrite the model on the database.
        transaction.overwrite(model);

        registration = update.value;
      });

      // Call the onRegistered method if the registration was successful.
      if (registration != null) {
        this.onRegistered(registration!);
      }
    }
  }

  //
  //
  //

  @override
  Future<ModelAppRegistration?> getNewRegistration() async {
    final createdAt = DateTime.now();
    final [notificationToken, ipAddress] = await Future.wait([
      this.firebaseMessaging.getToken(vapidKey: this.cloudMessagingVapidKey),
      getPublicIPAddress(),
    ]);
    if (notificationToken != null && ipAddress != null) {
      final registrationToken = ModelAppRegistration(
        createdAt: createdAt,
        ipAddress: ipAddress,
        loggedAt: createdAt,
        notificationToken: notificationToken,
      );
      return registrationToken;
    }
    return null;
  }

  //
  //
  //

  @override
  Future<void> subscribeToTopic(String topic) async {
    await this.firebaseMessaging.subscribeToTopic(topic);
  }

  //
  //
  //

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await this.firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension UniqueOnMapEntryIterableExtension<K, V> on Iterable<MapEntry<K, V>> {
  List<MapEntry<K, V>> unique() => uniqueEntries(this);
}

List<MapEntry<K, V>> uniqueEntries<K, V>(Iterable<MapEntry<K, V>> entries) {
  final uniqueKeys = <K>{};
  final uniqueValues = <V>{};
  final unique = <MapEntry<K, V>>[];

  for (var entry in entries) {
    if (!uniqueKeys.contains(entry.key) && !uniqueValues.contains(entry.value)) {
      uniqueKeys.add(entry.key);
      uniqueValues.add(entry.value);
      unique.add(MapEntry(entry.key, entry.value));
    }
  }

  return unique;
}
