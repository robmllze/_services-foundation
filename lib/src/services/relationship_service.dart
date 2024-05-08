//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RelationshipService extends CollectionServiceInterface<ModelRelationship> {
  //
  //
  //

  int? eventsPerRelationshipLimit;

  //
  //
  //

  RelationshipService({
    required super.serviceEnvironment,
    required super.limit,
    required this.eventsPerRelationshipLimit,
    required Set<String> initialPids,
  })  : this._memberPids = initialPids,
        super(ref: Schema.relationshipsRef());

  //
  //
  //

  @override
  Future<void> instantAdd(ModelRelationship model) async {
    await super.instantAdd(model);
    final id = model.id!;
    this._currentRelationshipIds.add(id);
    this._memberPids.addAll(model.memberPids ?? {});
  }

  //
  //
  //

  final pEventServicePool = Pod<Map<String, EventService>>({});
  var _currentRelationshipIds = <String>{};

  Set<String> get memberPids => this._memberPids;
  Set<String> _memberPids;

  //
  //
  //

  /// Adds new members then restarts the relationsho service.
  Future<void> addMembers(Set<String> memberPidsToAdd) async {
    await this.setMembers({
      ...this._memberPids,
      ...memberPidsToAdd,
    });
  }

  /// Sets the members then restarts the relationship service.
  Future<void> setMembers(Set<String> newMemberPids) async {
    final equals = setEquals(this._memberPids, newMemberPids);
    if (!equals) {
      this._memberPids = newMemberPids;
      await this.restartService();
    }
  }

  //
  //
  //

  @override
  void onData(Iterable<ModelRelationship> data) async {
    final updatedRelationshipIds = data.map((rel) => rel.id).nonNulls.toSet();
    await this._addRelationships(updatedRelationshipIds);
    await this._removeRelationships(updatedRelationshipIds);
    this._currentRelationshipIds = updatedRelationshipIds;
  }

  //
  //
  //

  Future<void> _addRelationships(Set<String> updatedRelationshipIds) async {
    final relationshipIdsToAdd = getSetDifference(
      this._currentRelationshipIds,
      updatedRelationshipIds,
    );
    Here().debugLog('Added relationships: $relationshipIdsToAdd');
    await this._addEventServices(relationshipIdsToAdd);
  }

  //
  //
  //

  Future<void> _addEventServices(Set<String> relationshipIdsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, EventService>>>[];
    for (final relationshipId in relationshipIdsToAdd) {
      final eventsService = EventService(
        serviceEnvironment: serviceEnvironment,
        ref: Schema.relationshipEventsRef(
          relationshipId: relationshipId,
        ),
        limit: this.eventsPerRelationshipLimit,
      );
      futureServicesToAdd.add(
        eventsService.restartService().then((_) {
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

  Future<void> _removeRelationships(Set<String> updatedRelationshipIds) async {
    final relationshipIdsToRemove = getSetDifference(
      updatedRelationshipIds,
      this._currentRelationshipIds,
    );
    Here().debugLog('Removed relationships: $relationshipIdsToRemove');
    await this._removeEventServices(relationshipIdsToRemove);
  }

  //
  //
  //

  Future<void> _removeEventServices(
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

  @override
  Stream<Iterable<ModelRelationship>> stream([int? limit]) {
    return this.serviceEnvironment.databaseQueryBroker.streamRelationshipsForAnyMembers(
          pids: this._memberPids,
          limit: limit,
        );
  }

  //
  //
  //

  @override
  void dispose() {
    final eventServicePool = this.pEventServicePool.value.values;
    for (final eventService in eventServicePool) {
      eventService.dispose();
    }
    super.dispose();
  }
}
