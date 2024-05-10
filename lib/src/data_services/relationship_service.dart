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

  RelationshipService({
    required super.serviceEnvironment,
    required super.limit,
    required Set<String> initialPids,
  })  : this._memberPids = initialPids,
        super(ref: Schema.relationshipsRef());

  //
  //
  //

  var _currentRelationshipIds = <String>{};

  Set<String> get memberPids => this._memberPids;
  Set<String> _memberPids;

  late final relationshipEvents = RelationshipEventServices(
    limit: 100,
    serviceEnvironment: this.serviceEnvironment,
    getRef: Schema.relationshipEventsRef,
  );

  late final relationshipMessages = RelationshipEventServices(
    limit: 20,
    serviceEnvironment: this.serviceEnvironment,
    getRef: Schema.relationshipMessagesRef,
  );

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
      await this.startService();
    }
  }

  //
  //
  //

  @override
  void onData(Iterable<ModelRelationship> data) async {
    final updatedRelationshipIds = data.map((rel) => rel.id).nonNulls.toSet();
    final equals = listEquals(
      updatedRelationshipIds.toList()..sort(),
      this._currentRelationshipIds.toList()..sort(),
    );
    if (!equals) {
      await this._addRelationships(updatedRelationshipIds);
      await this._removeRelationships(updatedRelationshipIds);
      this._currentRelationshipIds = updatedRelationshipIds;
    }
  }

  //
  //
  //

  Future<void> _addRelationships(Set<String> updatedRelationshipIds) async {
    final relationshipIdsToAdd = getSetDifference(
      this._currentRelationshipIds,
      updatedRelationshipIds,
    );
    if (relationshipIdsToAdd.isNotEmpty) {
      Here().debugLogInfo('Added relationships: $relationshipIdsToAdd');
      await this.relationshipEvents.add(relationshipIdsToAdd);
      await this.relationshipMessages.add(relationshipIdsToAdd);
    }
  }

  //
  //
  //

  Future<void> _removeRelationships(Set<String> updatedRelationshipIds) async {
    final relationshipIdsToRemove = getSetDifference(
      updatedRelationshipIds,
      this._currentRelationshipIds,
    );
    if (relationshipIdsToRemove.isNotEmpty) {
      Here().debugLog('Removed relationships: $relationshipIdsToRemove');
      await this.relationshipEvents.remove(relationshipIdsToRemove);
      await this.relationshipMessages.remove(relationshipIdsToRemove);
    }
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
    this.relationshipEvents.dispose();
    this.relationshipMessages.dispose();
    super.dispose();
  }
}
