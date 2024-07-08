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

final class UserPubService extends DocumentServiceInterface<ModelUserPub> {
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

  void startTransmittingLocation(LocationService locationService) async {
    this._locationService = locationService;
    await this.registerLocation();
    locationService.pCurrentLocation.addListener(this.registerLocation);
    await this._pIsTransmittingLocation.set(true);
  }

  //
  //
  //

  void stopTransmittingLocation() async {
    this._locationService?.pCurrentLocation.removeListener(this.registerLocation);
    this._locationService = null;
    await this._pIsTransmittingLocation.set(false);
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
        updateGReg: ModelRegistration(
          location: location,
          registeredAt: DateTime.now(),
        ),
      );
      await this.serviceEnvironment.databaseServiceBroker.mergeModel(update);
    } catch (e) {
      debugLogError(e);
    }
  }

  //
  //
  //

  Future<void> deleteLocation() async {
    this.serviceEnvironment.databaseServiceBroker.runTransaction((transaction) async {
      final ref = this.databaseRef();
      final userPub = await transaction.read(ref, ModelUserPub.fromJsonOrNull);
      if (userPub != null) {
        userPub.updateGReg?.location = null;
        transaction.overwrite(userPub);
      }
    });
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
