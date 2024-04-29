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

  final int eventServicesStreamLimit;

  //
  //
  //

  RelationshipService({
    required super.serviceEnvironment,
    required super.streamLimit,
    required this.eventServicesStreamLimit,
    required Set<String> initialPids,
  })  : this._memberPids = initialPids,
        super(ref: Schema.relationshipsRef());

  //
  //
  //

  final pEventServicePool = Pod<Map<String, EventService>>({});
  var _currentRelationshipIds = <String>{};

  Set<String> _memberPids;

  void addMembers(Set<String> memberPids) {
    this.setMembers({
      ...this.getMembers(),
      ...memberPids,
    });
  }

  void setMembers(Set<String> memberPids) {
    final equals = setEquals(this._memberPids, memberPids);
    if (!equals) {
      this._memberPids = memberPids;
      this.restartStream();
    }
  }

  Set<String> getMembers() => this._memberPids;

  //
  //
  //

  @override
  Future<void> initService() async {
    this.restartStream();
  }

  //
  //
  //

  void restartStream() {
    this.cancelSubscription();
    super.subscription = this.stream().listen((rels) async {
      final updatedRelationshipIds = rels.map((rel) => rel.id).nonNulls.toSet();
      await this._addRelationships(updatedRelationshipIds);
      await this._removeRelationships(updatedRelationshipIds);
      this._currentRelationshipIds = updatedRelationshipIds;
      await super.pValue.set(rels);
      if (this.completer.isCompleted == false) {
        this.completer.complete(rels);
      }
    });
  }

  //
  //
  //

  Future<void> _addRelationships(Set<String> updatedRelationshipIds) async {
    final relationshipIdsToAdd = getSetDifference(
      this._currentRelationshipIds,
      updatedRelationshipIds,
    );
    Here().debugLog('Relationships to add: $relationshipIdsToAdd');
    await this._onAddRelationships(relationshipIdsToAdd);
  }

  //
  //
  //

  Future<void> _onAddRelationships(Set<String> relationshipIdsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, EventService>>>[];
    for (final relationshipId in relationshipIdsToAdd) {
      final eventsService = EventService(
        serviceEnvironment: serviceEnvironment,
        ref: Schema.relationshipEventsRef(
          relationshipId: relationshipId,
        ),
        streamLimit: this.eventServicesStreamLimit,
      );
      futureServicesToAdd.add(
        eventsService.initService().then((_) {
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
    Here().debugLog('Relationship to remove: $relationshipIdsToRemove');
    await this._onRemoveRelationships(relationshipIdsToRemove);
  }

  //
  //
  //

  Future<void> _onRemoveRelationships(
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
  Stream<Iterable<ModelRelationship>> stream() {
    return this.serviceEnvironment.databaseQueryBroker.streamRelationshipsForAnyMembers(
          databaseServiceBroker: serviceEnvironment.databaseServiceBroker,
          memberPids: this.getMembers(),
          limit: this.streamLimit,
        );
  }

  //
  //
  //

  @override
  dynamic fromJson(Map<String, dynamic> modelData) {}
}
