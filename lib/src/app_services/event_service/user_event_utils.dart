//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licensing details can be found in the LICENSE file in the root directory.
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
    required String userPubId,
    required String eventId,
    bool archive = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.archiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventPath,
      archive: archive,
    );
  }

  static BatchWriteOperation<GenericModel> getArchiveEventOperation({
    required String userPubId,
    required String eventId,
    bool archive = true,
  }) {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    return EventUtils.getArchiveEventOperation(
      userPubId: userPubId,
      eventsRef: eventPath,
      archive: archive,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String eventId,
    bool hide = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.hideEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventPath,
      hide: hide,
    );
  }

  static BatchWriteOperation<GenericModel> getHideEventOperation({
    required String userPubId,
    required String eventId,
    bool hide = true,
  }) {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    return EventUtils.getHideEventOperation(
      userPubId: userPubId,
      eventsRef: eventPath,
      hide: hide,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String eventId,
    bool like = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.likeEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventPath,
      like: like,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String eventId,
    bool read = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.readEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventPath,
      read: read,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String eventId,
    bool receive = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.receiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventPath,
      receive: receive,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String eventId,
    required String eventTag,
    bool value = true,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
      eventId: eventId,
    );
    await EventUtils.tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
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
    required String userPubId,
    required String eventId,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: userPubId,
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
    required String senderPubId,
    required String receiverPubId,
    required String eventId,
    required Map<String, dynamic> eventDef,
    required EventDefType eventDefType,
  }) async {
    final eventPath = Schema.userEventsRef(
      userPubId: receiverPubId,
      eventId: eventId,
    );
    await EventUtils.sendEvent(
      serviceEnvironment: serviceEnvironment,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
      eventId: eventId,
      eventsRef: eventPath,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }

  //
  //
  //

  static BatchWriteOperation<ModelEvent> getSendEventOperation({
    required String senderPubId,
    required String receiverPubId,
    required String eventId,
    required Map<String, dynamic> eventDef,
    required EventDefType eventDefType,
  }) {
    final eventPath = Schema.userEventsRef(
      userPubId: receiverPubId,
      eventId: eventId,
    );
    return EventUtils.getSendEventOperation(
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final relationshipId = IdUtils.newRelationshipId();
    final eventDef = ModelConnectionRequestDef(
      id: eventId,
      relationshipId: relationshipId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelConnectionRequestAcceptedDef(
      id: eventId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelConnectionRequestRejectedDef(
      id: eventId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelationshipChangedDef(
      id: eventId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelationshipDisabledDef(
      id: eventId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
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
    required String senderPubId,
    required String receiverPubId,
  }) async {
    final eventId = IdUtils.newEventId();
    final eventDef = ModelRelationshipRemovedDef(
      id: eventId,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
    ).toJson();
    await sendEvent(
      eventId: eventId,
      receiverPubId: receiverPubId,
      senderPubId: senderPubId,
      serviceEnvironment: serviceEnvironment,
      eventDefType: EventDefType.RELATIONSHIP_REMOVED,
      eventDef: eventDef,
    );
  }
}
