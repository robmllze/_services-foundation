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

class RelationshipEventServices {
  //
  //
  //

  final int? limit;
  final ServiceEnvironment serviceEnvironment;
  final DataRef Function({
    String? relationshipId,
    String? eventId,
  }) getRef;

  //
  //
  //

  RelationshipEventServices({
    required this.limit,
    required this.serviceEnvironment,
    required this.getRef,
  });

  //
  //
  //

  final pEventServicePool = Pod<Map<String, EventService>>({});

  //
  //
  //

  Future<void> add(Set<String> relationshipIdsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, EventService>>>[];
    for (final relationshipId in relationshipIdsToAdd) {
      final ref = this.getRef(relationshipId: relationshipId);
      final eventsService = EventService(
        serviceEnvironment: serviceEnvironment,
        ref: ref,
        limit: this.limit,
      );
      // TODO: Think about this line:
      //eventsService.pValue.addListener(this.pEventServicePool.refresh);
      futureServicesToAdd.add(
        eventsService.startService().then((_) {
          Here().debugLogStart(
            'Added EventService for relationshipId: $relationshipId',
          );
          return MapEntry(relationshipId, eventsService);
        }),
      );
    }
    final servicesToAdd = await Future.wait(futureServicesToAdd);
    await this.pEventServicePool.update((e) => e..addEntries(servicesToAdd));
  }

  //
  //
  //

  Future<void> remove(
    Set<String> relationshipIdsToRemove,
  ) async {
    await this.pEventServicePool.update(
          (e) => e
            ..removeWhere(
              (relationshipId, eventService) {
                final remove = relationshipIdsToRemove.contains(relationshipId);
                if (remove) {
                  eventService.dispose();
                  Here().debugLogStop(
                    'Removed EventService for relationshipId: $relationshipId',
                  );
                }
                return remove;
              },
            ),
        );
  }

  //
  //
  //

  void dispose() {
    final eventServicePool = this.pEventServicePool.value.values;
    for (final eventService in eventServicePool) {
      eventService.dispose();
    }
  }
}
