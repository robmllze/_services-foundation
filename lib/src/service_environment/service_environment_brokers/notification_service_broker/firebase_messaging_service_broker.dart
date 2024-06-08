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

  static FirebaseMessagingServiceBroker? _instance;
  static FirebaseMessagingServiceBroker get instance {
    if (_instance == null) {
      throw Exception('FirebaseMessagingServiceBroker has not been initialized.');
    }
    return _instance!;
  }

  FirebaseMessagingServiceBroker._({
    required this.firebaseMessaging,
    required this.cloudMessagingVapidKey,
    required this.databaseServiceBroker,
    required this.functionsServiceBroker,
  });

  /// Returns the singleton instance of [FirebaseMessagingServiceBroker]. This
  /// service maintains global state nd only one instance is permitted. If an
  /// instance already exists, it throws an exception.
  factory FirebaseMessagingServiceBroker({
    required FirebaseMessaging firebaseMessaging,
    required String cloudMessagingVapidKey,
    required DatabaseServiceInterface databaseServiceBroker,
    required FunctionsServiceInterface functionsServiceBroker,
  }) {
    if (_instance != null) {
      throw Exception('FirebaseMessagingServiceBroker has already been initialized.');
    }
    _instance ??= FirebaseMessagingServiceBroker._(
      firebaseMessaging: firebaseMessaging,
      cloudMessagingVapidKey: cloudMessagingVapidKey,
      databaseServiceBroker: databaseServiceBroker,
      functionsServiceBroker: functionsServiceBroker,
    );
    return _instance!;
  }

  //
  //
  //

  StreamSubscription<dynamic>? _authorizationStatusStream;

  @override
  final pAuthorizationStatus = Pod<dynamic>(AuthorizationStatus.notDetermined, disposable: false);

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

    // Check the authorization status every 3 seconds.
    this._authorizationStatusStream?.cancel();
    this._authorizationStatusStream = pollingStream(
      this.checkAuthorizationStatus,
      const Duration(seconds: 3),
    ).listen((_) {});

    // Collect the current device status.
    final deviceInfo = getBasicDeviceInfo();
    final now = DateTime.now();
    final ipv4Address = await getPublicIPV4Address();
    final notificationToken =
        await this.firebaseMessaging.getToken(vapidKey: this.cloudMessagingVapidKey);

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

  /// Unregister the current device from the notification service. This means
  /// that the device will no longer receive notifications. This method
  @override
  Future<void> unregister({
    required String currentUserPid,
  }) async {
    // Delete the notification token.
    await this.firebaseMessaging.deleteToken();

    // Get the current ipv4Address.
    final ipv4Address = await getPublicIPV4Address();

    // Update the public user data by removing the current device registrations.
    await this.databaseServiceBroker.runTransaction((transaction) async {
      // Get the current ModelUserPub.
      final ref = Schema.userPubsRef(userPid: currentUserPid);
      final model = (await transaction.read(ref, ModelUserPub.fromJsonOrNull))!;

      // Remove the current device registrations.
      model.deviceRegistrations = model.deviceRegistrations?.map((k, v) {
        if (v.ipv4Address == ipv4Address) {
          return MapEntry(k, null);
        } else {
          return MapEntry(k, v);
        }
      }).nonNullValues;

      // Overwrite the model on the database.
      transaction.overwrite(model);
    });
  }

  //
  //
  //

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
  bool authorizationStatusGrantedSnapshot() {
    return this.pAuthorizationStatus.value == AuthorizationStatus.authorized;
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
}
