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

final class RelationshipEventUtils {
  //
  //
  //

  RelationshipEventUtils._();

  //
  //
  //

  static EventService? getEventServiceForRelationship({
    required Map<String, EventService>? eventServicePool,
    required String relationshipId,
  }) {
    final eventService = eventServicePool?[relationshipId];
    return eventService;
  }

  //
  //
  //

  static CreateOrUpdateOperation getSendEventOperation({
    required String senderPid,
    required String receiverPid,
    required String relationshipId,
    required String eventId,
    required GenericModel eventDef,
    required EventDefType eventDefType,
  }) {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    return EventUtils.getSendEventOperation(
      eventsRef: eventsRef,
      senderPid: senderPid,
      receiverPid: receiverPid,
      relationshipId: relationshipId,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }
}
