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
    final body = ModelConnectionRequestDef(
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
      relationshipId: relationshipId,
      serviceEnvironment: serviceEnvironment,
      body: body,
      topic: TopicType.CONNECTION_REQUEST,
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
    final body = ModelConnectionRequestAcceptedDef(
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
      relationshipId: newRelationshipId,
      serviceEnvironment: serviceEnvironment,
      topic: TopicType.CONNECTION_REQUEST_ACCEPTED,
      body: body,
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
    final body = ModelConnectionRequestRejectedDef(
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
      relationshipId: newRelationshipId,
      serviceEnvironment: serviceEnvironment,
      topic: TopicType.CONNECTION_REQUEST_REJECTED,
      body: body,
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
    final body = ModelRelChangedDef(
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
      relationshipId: newRelationshipId,
      serviceEnvironment: serviceEnvironment,
      topic: TopicType.RELATIONSHIP_CHANGED,
      body: body,
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
    final body = ModelRelDisabledDef(
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
      relationshipId: newRelationshipId,
      serviceEnvironment: serviceEnvironment,
      topic: TopicType.RELATIONSHIP_DISABLED,
      body: body,
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
    final body = ModelRelRemovedDef(
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
      relationshipId: newRelationshipId,
      serviceEnvironment: serviceEnvironment,
      topic: TopicType.RELATIONSHIP_REMOVED,
      body: body,
    );
  }
}
