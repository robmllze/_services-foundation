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
    final message = ModelMessageContent(
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
      message: message,
      topic: TopicType.CONNECTION_REQUEST,
    );
  }

  //
  //
  //

  static Future<void> sendConnectionRequestAcceptedEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPid,
    required String receiverPid,
  }) async {
    final eventId = IdUtils.newEventId();
    final message = ModelMessageContent(
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
      topic: TopicType.CONNECTION_REQUEST_ACCEPTED,
      message: message,
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
    final message = ModelMessageContent(
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
      topic: TopicType.CONNECTION_REQUEST_REJECTED,
      message: message,
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
    final message = ModelMessageContent(
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
      topic: TopicType.RELATIONSHIP_CHANGED,
      message: message,
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
    final message = ModelMessageContent(
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
      topic: TopicType.RELATIONSHIP_DISABLED,
      message: message,
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
    final message = ModelMessageContent(
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
      topic: TopicType.RELATIONSHIP_REMOVED,
      message: message,
    );
  }
}
