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

final class UserEventUtils {
  //
  //
  //

  UserEventUtils._();

  //
  //
  //

  static Future<void> sendConnectionRequestEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final relationshipId = IdUtils.newRelationshipId();
    final eventDef = ModelConnectionRequestDef(
      relationshipId: relationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDef: eventDef,
      eventDefType: EventDefType.CONNECTION_REQUEST,
    );
  }

  //
  //
  //

  static Future<void> sendConnectionRequestAcceptedEvent({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelConnectionRequestAcceptedDef(
      relationshipId: newRelationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.CONNECTION_REQUEST_ACCEPTED,
      eventDef: eventDef,
    );
  }

  //
  //
  //

  static Future<void> sendConnectionRequestRejectedEvent({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelConnectionRequestRejectedDef(
      relationshipId: newRelationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.CONNECTION_REQUEST_REJECTED,
      eventDef: eventDef,
    );
  }

  //
  //
  //

  static Future<void> sendRelationshipChangedEvent({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelChangedDef(
      relationshipId: newRelationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.RELATIONSHIP_CHANGED,
      eventDef: eventDef,
    );
  }

  //
  //
  //

  static Future<void> sendRelationshipDisabledEvent({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelDisabledDef(
      relationshipId: newRelationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.RELATIONSHIP_DISABLED,
      eventDef: eventDef,
    );
  }

  //
  //
  //

  static Future<void> sendRelationshipRemovedEvent({
    required ServiceEnvironment serviceEnvironment,
    required String newRelationshipId,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelRemovedDef(
      relationshipId: newRelationshipId,
      senderPid: senderPid,
      receiverPid: receiverPid,
    );
    await EventUtils.sendEvent(
      eventsRef: Schema.userEventsRef(
        userPid: receiverPid,
        eventId: eventId,
      ),
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.RELATIONSHIP_REMOVED,
      eventDef: eventDef,
    );
  }
}
