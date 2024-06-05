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
    this._init();
  }

  //
  //
  //

  /// NOTE: Not sure of this is necessary.
  Future<void> _init() async {
    await this.firebaseMessaging.setAutoInitEnabled(true);
    await this.firebaseMessaging.requestPermission();
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
  Future<void> registerToken({required String currentUserPid}) async {
    final registration = await this.getRegistration();
    if (registration != null) {
      this.databaseServiceBroker.runTransaction((transaction) async {
        // Get the current user pub.
        final ref = Schema.userPubsRef(userPid: currentUserPid);
        final model = (await transaction.read(ref, ModelUserPub.fromJsonOrNull))!;

        // End the transaction if the token is already registered.

        final tokens = model.notificationsRegistrations?.values.map((e) => e.token).nonNulls ?? [];
        if (tokens.isNotEmpty) {
          final latestToken = registration.token;
          if (tokens.contains(latestToken)) {
            return;
          }
        }

        // Get all registrations that have a different IP address to the new
        // registration, so that we don't have two registrations with the same
        // IP address.
        final unique = model.notificationsRegistrations?.entries
            .where((e) => e.value.ipAddress != registration.ipAddress)
            .toList()
            .toMap();

        model.notificationsRegistrations = {
          ...?unique,
          registration.createdAt!: registration,
        };
        transaction.overwrite(model);
      });
    }
  }

  //
  //
  //

  @override
  Future<ModelNotificationsRegistration?> getRegistration() async {
    final createdAt = DateTime.now();
    final [token, ipAddress] = await Future.wait([
      this.firebaseMessaging.getToken(vapidKey: this.cloudMessagingVapidKey),
      getPublicIPAddress(),
    ]);
    final registrationToken = ModelNotificationsRegistration(
      createdAt: createdAt,
      ipAddress: ipAddress,
      token: token,
    );
    return registrationToken;
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
