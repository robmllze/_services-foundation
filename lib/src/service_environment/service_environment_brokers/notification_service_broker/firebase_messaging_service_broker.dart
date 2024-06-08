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
import 'package:xyz_device_info/xyz_device_info.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirebaseMessagingServiceBroker extends NotificationServiceInterface {
  //
  //
  //

  final FirebaseMessaging firebaseMessaging;
  final String cloudMessagingVapidKey;
  final DatabaseServiceInterface databaseServiceBroker;
  final FunctionsServiceInterface functionsServiceBroker;

  //
  //
  //

  FirebaseMessagingServiceBroker({
    required this.firebaseMessaging,
    required this.cloudMessagingVapidKey,
    required this.databaseServiceBroker,
    required this.functionsServiceBroker,
  });

  //
  //
  //

  StreamSubscription<dynamic>? _authorizationStatusStream;

  //
  //
  //

  @override
  Future<void> send({
    required String title,
    required String body,
    required Set<String> destinationTokens,
  }) async {
    await functionsServiceBroker.sendNotifications(
      title: title,
      body: body,
      destinationTokens: destinationTokens,
    );
  }

  //
  //
  //

  @override
  void onRegisterDevice(ModelDeviceRegistration registration) {}

  //
  //
  //

  @override
  Future<void> register({
    required String currentUserPid,
    ModelLocation? location,
  }) async {
    // Check the authorization status and return early if not authorized.
    final authorizationStatus = await this.checkAuthorizationStatus();
    if (authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    // Periodically check the authorization status.
    this._authorizationStatusStream?.cancel();
    this._authorizationStatusStream = pollingStream(
      this.checkAuthorizationStatus,
      const Duration(seconds: 3),
    ).listen((_) {});

    // Collect the current device status.
    final deviceInfo = getBasicDeviceInfo();
    final now = DateTime.now();
    final [notificationToken, ipv4Address] = await Future.wait([
      this.firebaseMessaging.getToken(vapidKey: this.cloudMessagingVapidKey),
      getPublicIPV4Address(),
    ]);

    // Return early if the notificationToken or ipv4Address is null.
    if (notificationToken == null || ipv4Address == null) {
      return;
    }

    ModelDeviceRegistration? registration;

    await this.databaseServiceBroker.runTransaction((transaction) async {
      // Get the current ModelUserPub.
      final ref = Schema.userPubsRef(userPid: currentUserPid);
      final model = (await transaction.read(ref, ModelUserPub.fromJsonOrNull))!;

      // Get all unique registrations.
      final uniqueRegs = model.deviceRegistrations?.values.toSet();

      // Get all registrations with the same ipv4Address.
      final sameIpRegs = uniqueRegs?.where((e) => e.ipv4Address == ipv4Address);

      // Get all registrations with a different ipv4Address.
      final diffIpRegs = uniqueRegs?.where((e) => e.ipv4Address != ipv4Address);

      // Take the first entry from the sameIpRegs if it exists.
      final existing = sameIpRegs?.firstOrNull;

      // Update the current registration or create a new one.
      final update = (existing ?? ModelDeviceRegistration());
      update.id ??= IdUtils.newUuidV4();
      update.ipv4Address ??= ipv4Address;
      update.deviceRegisteredAt ??= now;
      update.deviceInfo = deviceInfo;
      update.lastLoggedInAt = now;
      update.location = location;
      update.notificationToken = notificationToken;

      // Update the model.
      model.deviceRegistrations = [...?diffIpRegs, update].map((e) => MapEntry(e.id!, e)).toMap();

      // Overwrite the model on the database.
      transaction.overwrite(model);

      // Set the registration to the update.
      registration = update;
    });

    // Call the onRegistered method if the registration was successful.
    if (registration != null) {
      this.onRegisterDevice(registration!);
    }
  }

  //
  //
  //

  @override
  final pAuthorizationStatus = Pod<dynamic>(AuthorizationStatus.notDetermined);

  @override
  Future<dynamic> checkAuthorizationStatus() async {
    final supported = await this.firebaseMessaging.isSupported();
    if (supported) {
      var settings = await this.firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        settings = await this.firebaseMessaging.requestPermission();
      }
      await this.pAuthorizationStatus.set(settings.authorizationStatus);
    } else {
      await this.pAuthorizationStatus.set(null);
    }
    return this.pAuthorizationStatus.value;
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

  //
  //
  //

  @override
  void dispose() async {
    this._authorizationStatusStream?.cancel();
    this.pAuthorizationStatus.dispose();
  }

  @override
  bool authorizationStatusGrantedSnapshot() {
    return this.pAuthorizationStatus.value == AuthorizationStatus.authorized;
  }
}
