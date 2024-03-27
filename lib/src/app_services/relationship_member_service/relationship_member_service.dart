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

class RelationshipMemberService<TModel extends Model,
    TDocumentService extends DocumentServiceInterface<TModel>> {
  //
  //
  //

  final RelationshipService relationshipService;
  final Iterable<RelationshipDefType> defTypes;
  final Iterable<String> memberIdPrefixes;
  final TDocumentService Function(
    ServiceEnvironment serviceEnvironment,
    String memberId,
  ) serviceInstantiator;

  //
  //
  //

  RelationshipMemberService({
    required this.relationshipService,
    required this.defTypes,
    required this.memberIdPrefixes,
    required this.serviceInstantiator,
  }) {
    this._init();
  }

  //
  //
  //

  final pMemberServicePool = Pod<Map<String, TDocumentService>>({});
  var _currentMemberIds = <String>{};
  Set<String> get currentMemberIds => this._currentMemberIds;

  //
  //
  //

  void _init() {
    this.relationshipService.pValue.addListener(this._listener);
  }

  void _listener() async {
    final relationships = this.relationshipService.pValue.value?.where((e) {
          final defType = e.defType ?? findRelationshipDefTypeFromMemberIds(e.memberIds);
          return this.defTypes.contains(defType);
        }) ??
        {};
    final memberIds = RelationshipUtils.extractMemberIdsFromRelationships(
      relationships,
      memberIdPrefixes: this.memberIdPrefixes,
    );
    await this._addMembers(memberIds);
    await this._removeMembers(memberIds);
    this._currentMemberIds = memberIds;
  }

  //
  //
  //

  Future<void> _addMembers(Set<String> updatedMemberIds) async {
    final memberIdsToAdd = getSetDifference(
      this._currentMemberIds,
      updatedMemberIds,
    );
    Here().debugLog('Members to add: $memberIdsToAdd');
    await this._onAddMembers(memberIdsToAdd);
  }

  //
  //
  //

  Future<void> _onAddMembers(Set<String> memberIdsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, TDocumentService>>>[];
    for (final memberId in memberIdsToAdd) {
      final memberService = this.serviceInstantiator(
        relationshipService.serviceEnvironment,
        memberId,
      );
      futureServicesToAdd.add(
        memberService.initService().then((_) {
          Here().debugLogStart(
            'Added service for memberId: $memberId',
          );
          return MapEntry(memberId, memberService);
        }),
      );
    }
    final servicesToAdd = await Future.wait(futureServicesToAdd);
    await this.pMemberServicePool.update((e) => e..addEntries(servicesToAdd));
  }

  //
  //
  //

  Future<void> _removeMembers(Set<String> updatedMemberIds) async {
    final memberIdsToRemove = getSetDifference(
      updatedMemberIds,
      this._currentMemberIds,
    );
    Here().debugLog('Members to remove: $memberIdsToRemove');
    await this._onRemoveMember(memberIdsToRemove);
  }

  //
  //
  //

  Future<void> _onRemoveMember(Set<String> memberIdsToRemove) async {
    await this.pMemberServicePool.update(
          (e) => e
            ..removeWhere(
              (memberId, eventService) {
                final remove = memberIdsToRemove.contains(memberId);
                if (remove) {
                  eventService.dispose();
                  Here().debugLogStop(
                    'Removed service for memberId: $memberId',
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
    this.pMemberServicePool.dispose();
  }
}
