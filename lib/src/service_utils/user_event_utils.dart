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

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    bool archive = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.archiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventsRef: eventPath,
      archive: archive,
    );
  }

  static CreateOrUpdateOperation getArchiveEventOperation({
    required String userPid,
    required String eventId,
    bool archive = true,
  }) {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    return EventUtils.getArchiveEventOperation(
      userPid: userPid,
      eventsRef: eventPath,
      archive: archive,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    bool hide = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.hideEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventsRef: eventPath,
      hide: hide,
    );
  }

  static CreateOrUpdateOperation getHideEventOperation({
    required String userPid,
    required String eventId,
    bool hide = true,
  }) {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    return EventUtils.getHideEventOperation(
      userPid: userPid,
      eventsRef: eventPath,
      hide: hide,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    bool like = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.likeEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventsRef: eventPath,
      like: like,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    bool read = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.readEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventsRef: eventPath,
      read: read,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    bool receive = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.receiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventsRef: eventPath,
      receive: receive,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
    required String eventTag,
    bool value = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: eventTag,
      eventsRef: eventPath,
      value: value,
    );
  }

  //
  //
  //

  static Future<void> deleteEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventId,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: userPid,
      eventId: eventId,
    );
    await EventUtils.deleteEvent(
      serviceEnvironment: serviceEnvironment,
      eventsRef: eventPath,
    );
  }

  //
  //
  //

  static Future<void> sendEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPid,
    required String receiverPid,
    required String eventId,
    required Model eventDef,
    required EventDefType eventDefType,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPid: receiverPid,
      eventId: eventId,
    );
    await EventUtils.sendEvent(
      serviceEnvironment: serviceEnvironment,
      senderPid: senderPid,
      receiverPid: receiverPid,
      eventId: eventId,
      eventsRef: eventPath,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }

  //
  //
  //

  static CreateOrUpdateOperation getSendEventOperation({
    required String senderPid,
    required String receiverPid,
    required String eventId,
    required GenericModel eventDef,
    required EventDefType eventDefType,
  }) {
    final eventPath = Schema.userEventsRef(
      userPid: receiverPid,
      eventId: eventId,
    );
    return EventUtils.getSendEventOperation(
      senderPid: senderPid,
      receiverPid: receiverPid,
      eventId: eventId,
      eventsRef: eventPath,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }

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
    await sendEvent(
      eventId: eventId,
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
    await sendEvent(
      eventId: eventId,
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
    await sendEvent(
      eventId: eventId,
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
    await sendEvent(
      eventId: eventId,
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
    await sendEvent(
      eventId: eventId,
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
    await sendEvent(
      eventId: eventId,
      receiverPid: receiverPid,
      senderPid: senderPid,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.RELATIONSHIP_REMOVED,
      eventDef: eventDef,
    );
  }
}
