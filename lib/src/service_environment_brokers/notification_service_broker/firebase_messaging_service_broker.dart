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

class FirebaseMessagingServiceBroker extends NotificationServiceInterface {
  //
  //
  //

  final FirebaseMessaging firebaseMessaging;
  final String cloudMessagingVapidKey;

  //
  //
  //

  FirebaseMessagingServiceBroker({
    required this.firebaseMessaging,
    required this.cloudMessagingVapidKey,
  });

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
  Future<String?> getToken() {
    return this.firebaseMessaging.getToken(
          vapidKey: this.cloudMessagingVapidKey,
        );
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
