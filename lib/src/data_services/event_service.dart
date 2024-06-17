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
          descendByField: ModelEvent.K_CREATED_AT,
        );

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
