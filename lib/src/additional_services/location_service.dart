//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:geolocator/geolocator.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class LocationService {
  //
  //
  //

  static LocationService? _instance;

  LocationService._();

  /// Returns the singleton instance of [LocationService]. This service
  /// maintains global state nd only one instance is permitted. If an instance
  /// already exists, it throws an exception.
  factory LocationService() {
    if (_instance != null) {
      throw Exception('LocationService has already been initialized.');
    }
    _instance = LocationService._();
    return _instance!;
  }

  //
  //
  //

  final pCurrentLocation = Pod<ModelLocation?>(null, disposable: false);

  ModelLocation? currentLocationSnapshot() => this.pCurrentLocation.value;

  final pAuthorizationStatus =
      Pod<LocationPermission>(LocationPermission.unableToDetermine, disposable: false);

  LocationPermission? locationPermissionSnapshot() => this.pAuthorizationStatus.value;

  StreamSubscription<Position>? _positionSubscription;

  StreamSubscription<void>? _authorizationStatusStream;

  //
  //
  //

  Future<ModelLocation?> start() async {
    ModelLocation? currentLocation;

    await checkAuthorizationStatus();

    this._authorizationStatusStream?.cancel();
    this._authorizationStatusStream = pollingStream(
      checkAuthorizationStatus,
      const Duration(seconds: 3),
    ).listen((_) {});

    if (this.authorizationStatusGrantedSnapshot()) {
      currentLocation = (await Geolocator.getCurrentPosition()).toLocationModel();
      await this.pCurrentLocation.set(currentLocation);
      this._positionSubscription?.cancel();

      this._positionSubscription = Geolocator.getPositionStream().listen((position) async {
        final currentLocation = position.toLocationModel();
        await this.pCurrentLocation.set(currentLocation);
      });
      return currentLocation;
    }
    return null;
  }

  //
  //
  //

  Future<LocationPermission> checkAuthorizationStatus() async {
    try {
      final supported = await Geolocator.isLocationServiceEnabled();
      if (supported) {
        var locationPermission = await Geolocator.checkPermission();
        if (locationPermission != LocationPermission.always &&
            locationPermission != LocationPermission.whileInUse) {
          locationPermission = await Geolocator.requestPermission();
        }
        await this.pAuthorizationStatus.set(locationPermission);
      } else {
        await this.pAuthorizationStatus.set(LocationPermission.unableToDetermine);
      }
    } catch (e) {
      await this.pAuthorizationStatus.set(LocationPermission.unableToDetermine);
    }
    return this.pAuthorizationStatus.value;
  }

  //
  //
  //

  /// Returns `true` if the location permission is granted. This is a volatile
  /// snapshot and depends on [pAuthorizationStatus].
  bool authorizationStatusGrantedSnapshot() {
    return this.pAuthorizationStatus.value == LocationPermission.whileInUse ||
        this.pAuthorizationStatus.value == LocationPermission.always;
  }

  //
  //
  //

  Future<void> stop() async {
    this._positionSubscription?.cancel();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ToLocationModelOnPositionExtension on Position {
  ModelLocation toLocationModel() {
    return ModelLocation(
      latitude: this.latitude,
      longitude: this.longitude,
      altitude: this.altitude,
    );
  }
}