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

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
      eventsRef: eventsRef,
      archive: archive,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
      eventsRef: eventsRef,
      hide: hide,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
      eventsRef: eventsRef,
      like: like,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
      eventsRef: eventsRef,
      read: read,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
      eventsRef: eventsRef,
      receive: receive,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
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
      userPid: userPid,
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
    required String userPid,
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
    required String senderPid,
    String? receiverPid,
    required String relationshipId,
    required String eventId,
    required EventDefType eventDefType,
    required GenericModel eventDef,
  }) async {
    final eventsRef = Schema.relationshipEventsRef(
      relationshipId: relationshipId,
      eventId: eventId,
    );
    await EventUtils.sendEvent(
      serviceEnvironment: serviceEnvironment,
      senderPid: senderPid,
      receiverPid: receiverPid,
      eventId: eventId,
      eventsRef: eventsRef,
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
      senderPid: senderPid,
      receiverPid: receiverPid,
      eventId: eventId,
      eventsRef: eventsRef,
      eventDef: eventDef,
      eventDefType: eventDefType,
    );
  }
}
