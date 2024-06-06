//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:location/location.dart';

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
  final pPermissionStatus = Pod<PermissionStatus?>(null);

  final _location = Location();

  StreamSubscription<LocationData>? _locationSubscription;

  //
  //
  //

  Future<bool> _init() async {
    // If already active, return true.
    if (this.pActive.value) {
      return true;
    }

    // Check if location services are enabled.
    var enabled = await this._location.serviceEnabled();
    await this.pEnabled.set(enabled);
    if (!enabled) {
      enabled = await this._location.requestService();
      await this.pEnabled.set(enabled);
      // If still not enabled, return false early.
      if (!enabled) return false;
    }

    // Check for location permissions.
    var permissionStatus = await this._location.hasPermission();
    await this.pPermissionStatus.set(permissionStatus);
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await this._location.requestPermission();
      await this.pPermissionStatus.set(permissionStatus);
      // If permission is denied or not granted after the request, return false.
      if (permissionStatus != PermissionStatus.granted) return false;
    }

    // Enable background mode and activate if permission is granted.
    if (permissionStatus == PermissionStatus.granted) {
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
    this._locationSubscription?.cancel();
    final active = await this._init();
    if (active) {
      currentLocation = (await this._location.getLocation()).toLocationModel();
      await this.pCurrentLocation.set(currentLocation);
      this._locationSubscription = this._location.onLocationChanged.listen((location) async {
        final currentLocation = location.toLocationModel();
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
    this._locationSubscription?.cancel();
  }

  //
  //
  //

  TPodList get plr => [
        this.pActive,
        this.pCurrentLocation,
        this.pEnabled,
        this.pPermissionStatus,
      ];

  bool activeSnapshot() => this.pActive.value;
  ModelLocation? currentLocationSnapshot() => this.pCurrentLocation.value;
  bool enabledSnapshot() => this.pEnabled.value;
  PermissionStatus? permissionStatusSnapshot() => this.pPermissionStatus.value;

  //
  //
  //

  Future<void> dispose() async {
    await this.stop();
    this.pActive.dispose();
    this.pCurrentLocation.dispose();
    this.pEnabled.dispose();
    this.pPermissionStatus.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ToLocationModelOnLocationDataExtension on LocationData {
  ModelLocation toLocationModel() {
    return ModelLocation(
      latitude: this.latitude ?? 0.0,
      longitude: this.longitude ?? 0.0,
      altitude: this.altitude ?? 0.0,
    );
  }
}
