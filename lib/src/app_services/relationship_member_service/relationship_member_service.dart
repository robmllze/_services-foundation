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
  var _currentMemberPids = <String>{};
  Set<String> get currentMemberPids => this._currentMemberPids;

  //
  //
  //

  void _init() {
    this.relationshipService.pValue.addListener(this._listener);
  }

  void _listener() async {
    final relationships = this.relationshipService.pValue.value?.where((e) {
          final defType = e.defType ?? findRelationshipDefTypeFromMemberPids(e.memberPids);
          return this.defTypes.contains(defType);
        }) ??
        {};
    final memberPids = RelationshipUtils.extractMemberPidsFromRelationships(
      relationships,
      memberIdPrefixes: this.memberIdPrefixes,
    );
    await this._addMembers(memberPids);
    await this._removeMembers(memberPids);
    this._currentMemberPids = memberPids;
  }

  //
  //
  //

  Future<void> _addMembers(Set<String> updatedMemberPids) async {
    final memberPidsToAdd = getSetDifference(
      this._currentMemberPids,
      updatedMemberPids,
    );
    Here().debugLog('Members to add: $memberPidsToAdd');
    await this._onAddMembers(memberPidsToAdd);
  }

  //
  //
  //

  Future<void> _onAddMembers(Set<String> memberPidsToAdd) async {
    final futureServicesToAdd = <Future<MapEntry<String, TDocumentService>>>[];
    for (final memberId in memberPidsToAdd) {
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

  Future<void> _removeMembers(Set<String> updatedMemberPids) async {
    final memberPidsToRemove = getSetDifference(
      updatedMemberPids,
      this._currentMemberPids,
    );
    Here().debugLog('Members to remove: $memberPidsToRemove');
    await this._onRemoveMember(memberPidsToRemove);
  }

  //
  //
  //

  Future<void> _onRemoveMember(Set<String> memberPidsToRemove) async {
    await this.pMemberServicePool.update(
          (e) => e
            ..removeWhere(
              (memberId, eventService) {
                final remove = memberPidsToRemove.contains(memberId);
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
