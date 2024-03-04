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

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    bool archive = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.archiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventsRef,
      archive: archive,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    bool hide = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.hideEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventsRef,
      hide: hide,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    bool like = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.likeEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventsRef,
      like: like,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    bool read = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.readEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventsRef,
      read: read,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    bool receive = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.receiveEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventsRef: eventsRef,
      receive: receive,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
    required String eventTag,
    bool value = true,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPubId: userPubId,
      eventTag: eventTag,
      eventsRef: eventsRef,
      value: value,
    );
  }

  //
  //
  //

  static Future<void> deleteEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPubId,
    required String relationshipId,
    required String eventId,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.deleteEvent(
      serviceEnvironment: serviceEnvironment,
      eventsRef: eventsRef,
    );
  }

  //
  //
  //

  static Future<void> sendEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPubId,
    String? receiverPubId,
    required String relationshipId,
    required String eventId,
    required EventDefType eventDefType,
    required Map<String, dynamic> eventDef,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.sendEvent(
      serviceEnvironment: serviceEnvironment,
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
      eventId: eventId,
      eventsRef: eventsRef,
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
    required String relationshipId,
    required String eventId,
    required Map<String, dynamic> eventDef,
    required EventDefType eventDefType,
  }) {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    return EventUtils.getSendEventOperation(
      senderPubId: senderPubId,
      receiverPubId: receiverPubId,
      eventId: eventId,
      eventsRef: eventsRef,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }
}
