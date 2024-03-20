//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// X|Y|Z & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import "/_common.dart";

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RelationshipService
    extends CollectionServiceInterface<ModelRelationship> {
  //
  //
  //

  final String userPubId;
  final pEventServicePool = Pod<Map<String, EventService>>({});

  var _currentRelationshipIds = <String>{};

  final pConnectionServicePool = Pod<Map<String, UserPubService>>({});
  var _currentConnectionIds = <String>{};

  //
  //
  //

  RelationshipService({
    required super.serviceEnvironment,
    required super.limit,
    required this.userPubId,
  }) : super(ref: Schema.relationshipsRef());

  //
  //
  //

  @override
  Future<void> initService() async {
    this.cancelSubscriptions();
    super.subscription = this.stream().listen((e) async {
      final updatedRelationshipIds = e.map((e) => e.id).nonNulls.toSet();
      await this._addRelationships(updatedRelationshipIds);
      await this._removeRelationships(updatedRelationshipIds);
      this._currentRelationshipIds = updatedRelationshipIds;
      final updatedConnectionIds =
          RelationshipUtils.extractMemberIdsFromRelationships(e);
      await this._addConnections(updatedConnectionIds);
      await this._removeConnections(updatedConnectionIds);
      this._currentConnectionIds = updatedConnectionIds;
      await super.pValue.set(e);
      if (this.completer.isCompleted == false) {
        this.completer.complete(e);
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
    Here().debugLog("Relationships to add: $relationshipIdsToAdd");
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
        limit: 80,
      );
      futureServicesToAdd.add(
        eventsService.initService().then((_) {
          Here().debugLogStart(
            "Added EventService for relationshipId: $relationshipId",
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
    Here().debugLog("Relationship to remove: $relationshipIdsToRemove");
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
              (final relationshipId, final eventService) {
                final remove = relationshipIdsToRemove.contains(relationshipId);
                if (remove) {
                  eventService.dispose();
                  Here().debugLogStop(
                    "Removed EventService for relationshipId: $relationshipId",
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

  Future<void> _addConnections(Set<String> updatedConnectionIds) async {
    final connectionIdsToAdd = getSetDifference(
      this._currentConnectionIds,
      updatedConnectionIds,
    );
    Here().debugLog("Connections to add: $connectionIdsToAdd");
    await this._onAddConnections(connectionIdsToAdd);
  }

  //
  //
  //

  Future<void> _onAddConnections(Set<String> connectionIdsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, UserPubService>>>[];
    for (final connectionId in connectionIdsToAdd) {
      final connectionService = UserPubService(
        serviceEnvironment: serviceEnvironment,
        id: connectionId,
      );
      futureServicesToAdd.add(
        connectionService.initService().then((_) {
          Here().debugLogStart(
            "Added User Service for connectionId $connectionId",
          );
          return MapEntry(connectionId, connectionService);
        }),
      );
    }
    final servicesToAdd = await Future.wait(futureServicesToAdd);
    await this
        .pConnectionServicePool
        .update((e) => e..addEntries(servicesToAdd));
  }

  //
  //
  //

  Future<void> _removeConnections(Set<String> updatedConnectionIds) async {
    final connectionIdsToRemove = getSetDifference(
      updatedConnectionIds,
      this._currentConnectionIds,
    );
    Here().debugLog("Connections to remove: $connectionIdsToRemove");
    await this._onRemoveConnection(connectionIdsToRemove);
  }

  //
  //
  //

  Future<void> _onRemoveConnection(Set<String> connectionIdsToRemove) async {
    await this.pConnectionServicePool.update(
          (e) => e
            ..removeWhere(
              (final connectionId, final eventService) {
                final remove = connectionIdsToRemove.contains(connectionId);
                if (remove) {
                  eventService.dispose();
                  Here().debugLogStop(
                    "Removed UserPubService for connectionId: $connectionId",
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
    return this
        .serviceEnvironment
        .databaseQueryBroker
        .queryRelationshipsForMembers(
      databaseService: serviceEnvironment.databaseServiceBroker,
      memberIds: {this.userPubId},
    );
  }

  //
  //
  //

  @override
  dynamic fromJson(Map<String, dynamic> modelData) {}
}
