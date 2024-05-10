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

class RelationshipMemberService<TModel extends Model,
    TDocumentService extends DocumentServiceInterface<TModel>> {
  //
  //
  //

  final RelationshipService relationshipService;
  final Iterable<RelationshipDefType> defTypes;
  final Iterable<String> memberPidPrefixes;
  final TDocumentService Function(
    ServiceEnvironment serviceEnvironment,
    String memberPid,
  ) serviceInstantiator;

  //
  //
  //

  RelationshipMemberService({
    required this.relationshipService,
    required this.defTypes,
    required this.memberPidPrefixes,
    required this.serviceInstantiator,
  }) {
    this._init();
  }

  //
  //
  //

  final pMemberServicePool = Pod<Map<String, TDocumentService>>({});
  var _currentMemberPids = <String>{};
  Set<String> get currentMemberPids => this._currentMemberPids;

  //
  //
  //

  void _init() async {
    // Refresh immediately.
    await this.refresh();
    // Refresh when the relationship pool changes.
    this.relationshipService.pValue.addListener(this.refresh);
  }

  //
  //
  //

  /// Updates [pMemberServicePool] and [currentMemberPids] from the latest
  /// relationship pool in [relationshipService].
  @protected
  Future<void> refresh() async {
    final relationshipPool = this.relationshipService.pValue.value?.where((e) {
          final defType = e.defType;
          return this.defTypes.contains(defType);
        }) ??
        {};
    final memberPids = RelationshipUtils.extractMemberPids(
      relationshipPool: relationshipPool,
      memberPidPrefixes: this.memberPidPrefixes,
    );
    final equals = listEquals(
      memberPids.toList()..sort(),
      this._currentMemberPids.toList()..sort(),
    );
    if (!equals) {
      await this._add(memberPids);
      await this._remove(memberPids);
      this._currentMemberPids = memberPids;

      // Include all relationships concerning the current members to the provided
      // relationship pool.
      this.relationshipService.addMembers(
            this
                .currentMemberPids
                .where((e) => this.memberPidPrefixes.contains(IdUtils.getPrefix(e)))
                .toSet(),
          );
    }
  }

  //
  //
  //

  // TODO: Fix/redo this method.
  Future<void> instantAdd(TModel member) async {
    // final memberPid = member.id!;
    // final memberService = this.serviceInstantiator(
    //   relationshipService.serviceEnvironment,
    //   memberPid,
    // );
    // await memberService.pValue.set(member);
    // await memberService.restartService();
    // Here().debugLogStart(
    //   'Manually added service for memberPid: $memberPid',
    // );
    // await this.pMemberServicePool.update((e) => e..[memberPid] = memberService);
  }

  //
  //
  //

  Future<void> _add(Set<String> updatedMemberPids) async {
    final memberPidsToAdd = getSetDifference(
      this._currentMemberPids,
      updatedMemberPids,
    );
    if (memberPidsToAdd.isNotEmpty) {
      Here().debugLog('Members to add: $memberPidsToAdd');
      await this.addMembers(memberPidsToAdd);
    }
  }

  //
  //
  //

  Future<void> addMembers(Set<String> memberPidsToAdd) async {
    if (memberPidsToAdd.isNotEmpty) {
      final futureServicesToAdd = <Future<MapEntry<String, TDocumentService>>>[];
      for (final memberPid in memberPidsToAdd) {
        final memberService = this.serviceInstantiator(
          relationshipService.serviceEnvironment,
          memberPid,
        );
        futureServicesToAdd.add(
          memberService.startService().then((_) {
            Here().debugLogStart(
              'Added service for memberPid: $memberPid',
            );
            return MapEntry(memberPid, memberService);
          }),
        );
      }
      final servicesToAdd = await Future.wait(futureServicesToAdd);
      await this.pMemberServicePool.update((e) => e..addEntries(servicesToAdd));
    }
  }

  //
  //
  //

  Future<void> _remove(Set<String> updatedMemberPids) async {
    final memberPidsToRemove = getSetDifference(
      updatedMemberPids,
      this._currentMemberPids,
    );
    if (memberPidsToRemove.isNotEmpty) {
      Here().debugLog('Members to remove: $memberPidsToRemove');
      await this.removeMembers(memberPidsToRemove);
    }
  }

  //
  //
  //

  Future<void> removeMembers(Set<String> memberPidsToRemove) async {
    if (memberPidsToRemove.isNotEmpty) {
      await this.pMemberServicePool.update(
            (e) => e
              ..removeWhere(
                (memberPid, eventService) {
                  final remove = memberPidsToRemove.contains(memberPid);
                  if (remove) {
                    eventService.dispose();
                    Here().debugLogStop(
                      'Removed service for memberPid: $memberPid',
                    );
                  }
                  return remove;
                },
              ),
          );
    }
  }

  //
  //
  //

  void dispose() {
    final values = this.pMemberServicePool.value.values;
    for (final value in values) {
      value.dispose();
    }
    this.pMemberServicePool.dispose();
  }
}
