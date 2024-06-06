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

  LocationService();

  //
  //
  //

  final pActive = Pod<bool>(false);
  final pCurrentLocation = Pod<ModelLocation?>(null);
  final pEnabled = Pod<bool>(false);
  final pLocationPermission = Pod<LocationPermission?>(null);

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<void>? _locationPermissionSubscription;

  //
  //
  //

  Future<bool> _init() async {
    // If already active, return true.
    if (this.pActive.value) {
      return true;
    }

    // Check if location services are enabled.

    var enabled = await Geolocator.isLocationServiceEnabled();
    await this.pEnabled.set(enabled);
    // If still not enabled, return false early.
    if (!enabled) {
      return false;
    }

    // Check for location permissions.
    var permissionStatus = await Geolocator.checkPermission();
    await this.pLocationPermission.set(permissionStatus);
    if (permissionStatus == LocationPermission.denied) {
      permissionStatus = await Geolocator.requestPermission();
      await this.pLocationPermission.set(permissionStatus);
      // If permission is denied or not granted after the request, return false.
      if (permissionStatus == LocationPermission.denied ||
          permissionStatus == LocationPermission.deniedForever) return false;
    }

    // Enable background mode and activate if permission is granted.
    if (permissionStatus == LocationPermission.whileInUse ||
        permissionStatus == LocationPermission.always) {
      await this.pActive.set(true);
      return true;
    }

    // Default return false if none of the above conditions are met.
    return false;
  }

  //
  //
  //

  Future<ModelLocation?> start() async {
    ModelLocation? currentLocation;

    final active = await this._init();

    this._locationPermissionSubscription?.cancel();

    this._locationPermissionSubscription = pollingStream(
      this._init,
      const Duration(seconds: 3),
    ).listen((_) {});

    if (active) {
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

  Future<void> stop() async {
    this._positionSubscription?.cancel();
  }

  //
  //
  //

  TPodList get plr => [
        this.pActive,
        this.pCurrentLocation,
        this.pEnabled,
        this.pLocationPermission,
      ];

  bool activeSnapshot() => this.pActive.value;
  ModelLocation? currentLocationSnapshot() => this.pCurrentLocation.value;
  bool enabledSnapshot() => this.pEnabled.value;
  LocationPermission? locationPermissionSnapshot() => this.pLocationPermission.value;
  bool permissionStatusGrantedSnapshot() =>
      this.locationPermissionSnapshot() == LocationPermission.whileInUse ||
      this.locationPermissionSnapshot() == LocationPermission.always;

  //
  //
  //

  Future<void> dispose() async {
    await this.stop();
    this.pActive.dispose();
    this.pCurrentLocation.dispose();
    this.pEnabled.dispose();
    this.pLocationPermission.dispose();
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
