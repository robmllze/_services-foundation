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

final class RelationshipService extends CollectionServiceInterface<ModelRelationship> {
  //
  //
  //

  RelationshipService({
    required super.serviceEnvironment,
    required super.limit,
    required Set<String> initialPids,
  })  : this._memberPids = initialPids,
        super(ref: Schema.relationshipsRef()) {
    this.pValue
      ..addListener(() => this._removeObsoleteRelationships(eventServices))
      ..addListener(() => this._removeObsoleteRelationships(messageEventServices));
  }

  //
  //
  //

  var _currentRelationshipIds = <String>{};

  Set<String> get memberPids => this._memberPids;
  Set<String> _memberPids;

  late final eventServices = RelationshipEventServices(
    associatedRelationshipService: this,
    limit: 100,
    serviceEnvironment: this.serviceEnvironment,
    getRef: Schema.relationshipEventsRef,
  );

  late final messageEventServices = RelationshipEventServices(
    associatedRelationshipService: this,
    limit: 20,
    serviceEnvironment: this.serviceEnvironment,
    getRef: Schema.relationshipMessageEventsRef,
  );

  //
  //
  //

  Future<void> _removeObsoleteRelationships(RelationshipEventServices eventServices) async {
    final pEventServicePool = eventServices.pEventServicePool;
    final relationships = this.pValue.value;
    final relationshipIds = pEventServicePool.value.keys;
    if (relationships != null) {
      final activeRelationships = relationships.where((e) => relationshipIds.contains(e.id));
      final obsoleteRelationships = activeRelationships.where((e) {
        return e.isObsolete(); // || e.isArchivedBy();
      });
      if (obsoleteRelationships.isNotEmpty) {
        final obsoleteRelationshipIds = obsoleteRelationships.map((e) => e.id);
        await pEventServicePool.podOrNull!.update(
          (e) => e
            ..removeWhere((relationshipId, eventService) {
              final isObsolete = obsoleteRelationshipIds.contains(relationshipId);
              if (isObsolete) {
                debugLog('Removed obsolete relationship: $relationshipId');
                eventService.dispose();
                return true;
              } else {
                return false;
              }
            }),
        );
      }
    }
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
      debugLog('Added relationships: $relationshipIdsToAdd');
      this.eventServices.add(relationshipIdsToAdd);
      this.messageEventServices.add(relationshipIdsToAdd);
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
      debugLogStop('Removed relationships: $relationshipIdsToRemove');
      await this.eventServices.remove(relationshipIdsToRemove);
      await this.messageEventServices.remove(relationshipIdsToRemove);
    }
  }

  //
  //
  //

  @override
  Stream<Iterable<ModelRelationship>> stream([int? limit]) {
    return this.serviceEnvironment.databaseQueryBroker.streamRelationshipsForAnyMember(
          memberPids: this._memberPids,
          limit: limit,
        );
  }

  //
  //
  //

  @override
  void dispose() {
    this.eventServices.dispose();
    this.messageEventServices.dispose();
    super.dispose();
  }
}
