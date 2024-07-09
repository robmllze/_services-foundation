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

  final RelationshipService associatedRelationshipService;
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
    required this.associatedRelationshipService,
    required this.limit,
    required this.serviceEnvironment,
    required this.getRef,
  });

  //
  //
  //

  final _pEventServicePool = Pod<Map<String, EventService>>({});

  PodListenable<Map<String, EventService>> get pEventServicePool => this._pEventServicePool;

  //
  //
  //

  Future<void> add(Set<String> relationshipIdsToAdd) async {
    final temp = <Future<MapEntry<String, EventService>>>[];
    for (final relationshipId in relationshipIdsToAdd) {
      final ref = this.getRef(relationshipId: relationshipId);
      final eventService = EventService(
        serviceEnvironment: serviceEnvironment,
        ref: ref,
        limit: this.limit,
      );
      temp.add(eventService.startService().then((_) => MapEntry(relationshipId, eventService)));
      debugLogStart(
        'Added EventService for relationship: $relationshipId',
      );
    }
    final entries = await Future.wait(temp);
    await this._pEventServicePool.update((e) => e..addEntries(entries));
  }

  //
  //
  //

  Future<void> remove(
    Set<String> relationshipIdsToRemove,
  ) async {
    await this._pEventServicePool.update(
          (e) => e
            ..removeWhere(
              (relationshipId, eventService) {
                final remove = relationshipIdsToRemove.contains(relationshipId);
                if (remove) {
                  eventService.dispose();
                  debugLogStop(
                    'Removed EventService for relationship: $relationshipId',
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
