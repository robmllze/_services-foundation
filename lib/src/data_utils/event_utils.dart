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

final class EventUtils {
  //
  //
  //

  EventUtils._();

  //
  //
  //

  static int getUnreadEventCount({
    required Iterable<ModelEvent>? eventPool,
    Set<String?> blacklistCreatedBy = const {},
    Set<String?> whitelistCreatedBy = const {},
    Set<TopicType> topics = const {},
    bool includeArchived = false,
    bool includeHidden = false,
    bool includeRead = false,
  }) {
    return eventPool?.nullIfEmpty
            ?.where(
              (e) =>
                  (topics.isEmpty || topics.contains(e.topic)) &&
                  (blacklistCreatedBy.isEmpty ||
                      blacklistCreatedBy.contains(e.createdBy) == false) &&
                  (whitelistCreatedBy.isEmpty ||
                      whitelistCreatedBy.contains(e.createdBy) == true) &&
                  (!includeHidden && !e.isHidden) &&
                  (!includeArchived && !e.isArchived) &&
                  (!includeRead && !e.isRead),
            )
            .length ??
        0;
  }

  //
  //
  //

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required DataRef eventsRef,
    bool archive = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_ARCHIVED,
      eventsRef: eventsRef,
      value: archive,
    );
  }

  static CreateOrUpdateOperation getArchiveEventOperation({
    required String userPid,
    required DataRef eventsRef,
    bool archive = true,
  }) {
    return getTagEventOperation(
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_ARCHIVED,
      eventsRef: eventsRef,
      value: archive,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required DataRef eventsRef,
    bool hide = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_HIDDEN,
      eventsRef: eventsRef,
      value: hide,
    );
  }

  static CreateOrUpdateOperation getHideEventOperation({
    required String userPid,
    required DataRef eventsRef,
    bool hide = true,
  }) {
    return getTagEventOperation(
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_HIDDEN,
      eventsRef: eventsRef,
      value: hide,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required DataRef eventsRef,
    bool like = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_LIKED,
      eventsRef: eventsRef,
      value: like,
    );
  }

  static CreateOrUpdateOperation getLikeEventOperation({
    required String userPid,
    required String eventId,
    required DataRef eventsRef,
    bool like = true,
  }) {
    return getTagEventOperation(
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_LIKED,
      eventsRef: eventsRef,
      value: like,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required DataRef eventsRef,
    bool read = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_READ,
      eventsRef: eventsRef,
      value: read,
    );
  }

  static CreateOrUpdateOperation getReadEventOperation({
    required String userPid,
    required DataRef eventsRef,
    bool read = true,
  }) {
    return getTagEventOperation(
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_READ,
      eventsRef: eventsRef,
      value: read,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required DataRef eventsRef,
    bool receive = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_RECEIVED,
      eventsRef: eventsRef,
      value: receive,
    );
  }

  static CreateOrUpdateOperation getReceiveEventOperation({
    required String userPid,
    required DataRef eventsRef,
    bool receive = true,
  }) {
    return getTagEventOperation(
      userPid: userPid,
      eventTag: ModelEvent.K_WHEN_RECEIVED,
      eventsRef: eventsRef,
      value: receive,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String userPid,
    required String eventTag,
    required DataRef eventsRef,
    required bool value,
  }) async {
    await serviceEnvironment.databaseServiceBroker.updateModel(
      DataModel(
        data: {
          ModelEvent.K_REF: eventsRef.toJson(),
          eventTag: {
            userPid: value ? DateTime.now().toUtc().toIso8601String() : '',
          },
        },
      ),
    );
  }

  static CreateOrUpdateOperation getTagEventOperation({
    required String userPid,
    required String eventTag,
    required DataRef eventsRef,
    required bool value,
  }) {
    return CreateOrUpdateOperation(
      model: DataModel(
        data: {
          ModelEvent.K_REF: eventsRef.toJson(),
          eventTag: {
            userPid: value ? DateTime.now().toUtc().toIso8601String() : '',
          },
        },
      ),
    );
  }

  //
  //
  //

  static Future<void> deleteEvent({
    required ServiceEnvironment serviceEnvironment,
    required DataRef eventsRef,
  }) async {
    await serviceEnvironment.databaseServiceBroker.deleteModel(eventsRef);
  }

  //
  //
  //

  static Future<void> sendEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPid,
    String? receiverPid,
    required String relationshipId,
    required DataRef eventsRef,
    required Model body,
    required TopicType topic,
  }) async {
    await getSendEventOperation(
      senderPid: senderPid,
      receiverPid: receiverPid,
      relationshipId: relationshipId,
      eventsRef: eventsRef,
      body: body,
      topic: topic,
    ).execute(serviceEnvironment);
  }

  static CreateOrUpdateOperation getSendEventOperation({
    required String senderPid,
    String? receiverPid,
    required String relationshipId,
    required DataRef eventsRef,
    required Model body,
    required TopicType topic,
  }) {
    final eventModel = ModelEvent(
      ref: eventsRef,
      id: eventsRef.id!,
      relationshipId: relationshipId,
      memberPids: {
        senderPid,
        if (receiverPid != null) receiverPid,
      },
      createdAt: DateTime.now(),
      createdBy: senderPid,
      body: DataModel(data: body.toJson()),
      topic: topic,
    );
    return CreateOrUpdateOperation(model: eventModel);
  }
}
