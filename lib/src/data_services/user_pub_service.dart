//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:_data/_common.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class UserPubService extends DocumentServiceInterface<ModelUserPub> {
  //
  //
  //

  UserPubService({
    required super.serviceEnvironment,
    required super.id,
  });

  //
  //
  //

  LocationService? _locationService;

  //
  //
  //

  final _pIsTransmittingLocation = Pod<bool>(false);

  PodListenable<bool> get pIsTransmittingLocation => this._pIsTransmittingLocation;

  //
  //
  //

  @override
  DataRef databaseRef() => Schema.userPubsRef(userPid: id);

  //
  //
  //

  @override
  ModelUserPub? fromJsonOrNull(Map<String, dynamic>? data) {
    return ModelUserPub.fromJsonOrNull(data);
  }

  //
  //
  //

  void startTransmittingLocation(LocationService locationService) {
    this._locationService = locationService;
    locationService.pCurrentLocation.addListener(this.registerLocation);
    this._pIsTransmittingLocation.set(true);
  }

  //
  //
  //

  void stopTransmittingLocation() {
    this._locationService?.pCurrentLocation.removeListener(this.registerLocation);
    this._locationService = null;
    this._pIsTransmittingLocation.set(false);
  }

  //
  //
  //

  Future<void> registerLocation() async {
    try {
      final location = this._locationService?.currentLocationSnapshot();
      if (location == null) {
        return;
      }
      final update = ModelUserPub(
        ref: this.databaseRef(),
        registration: ModelRegistration(
          location: location,
          registeredAt: DateTime.now(),
        ),
      );
      await this.serviceEnvironment.databaseServiceBroker.mergeModel(update);
    } catch (e) {
      Here().debugLogError(e);
    }
  }

  //
  //
  //

  @override
  void dispose() {
    super.dispose();
    this.stopTransmittingLocation();
  }
}
