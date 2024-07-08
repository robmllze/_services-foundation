//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:math' as math;

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class EventService extends CollectionServiceInterface<ModelEvent> {
  //
  //
  //

  EventService({
    required super.serviceEnvironment,
    required super.ref,
    required super.limit,
  }) : super(
          descendByField: '${ModelFileEntry.K_CREATED_G_REG}.${ModelRegistration.K_REGISTERED_BY}',
        );

  //
  //
  //

  Future<void> addEvent(ModelEvent event) async {
    await this.pValue.podOrNull?.update((e) => [...?e, event]);
  }

  //
  //
  //

  Future<void> removeEvent(String eventId) async {
    await this.pValue.podOrNull?.update(
      (e) {
        if (e != null) {
          return List.of(e)..removeWhere((e) => e.id == eventId);
        }
        return null;
      },
    );
  }

  //
  //
  //

  /// Restarts the service with a new limit. Specify [delta] to change the
  /// limit by a certain amount. This amount will be added to the current limit
  /// and the result will be clamped between [minimum] and [maximum].
  Future<void> loadMoreEvents({
    int delta = 10,
    int maximum = 100,
    int minimum = 10,
  }) async {
    final tryLimit = (this.limit ?? minimum) + delta;
    final clampedLimit = math.min(math.max(tryLimit, minimum), maximum);
    if (clampedLimit != this.limit) {
      await this.startService(limit: clampedLimit);
    }
  }

  //
  //
  //

  /// Same as [loadMoreEvents] but with a negative [delta].
  Future<void> loadFewerEvents({
    int delta = 10,
    int maximum = 100,
    int minimum = 10,
  }) async {
    await this.loadMoreEvents(
      delta: -delta,
      maximum: maximum,
      minimum: minimum,
    );
  }

  //
  //
  //

  @override
  ModelEvent? fromJsonOrNull(Map<String, dynamic>? data) {
    return ModelEvent.fromJsonOrNull(data);
  }
}
