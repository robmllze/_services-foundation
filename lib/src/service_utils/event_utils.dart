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
    String? senderPid,
    Set<EventDefType> eventTypes = const {},
    bool includeArchived = false,
    bool includeHidden = false,
    bool includeRead = false,
  }) {
    return eventPool?.nullIfEmpty
            ?.where(
              (e) =>
                  (eventTypes.isEmpty || eventTypes.contains(e.defType)) &&
                  (senderPid == null || e.whenSent?.keys.contains(senderPid) != true) &&
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

  static List<ModelEvent>? sortEventsByDateSentAscending(
    Iterable<ModelEvent>? eventModels,
  ) {
    return (eventModels?.toList()
      ?..sort((a, b) {
        return a.firstSent!.compareTo(b.firstSent!);
      }));
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

  static BatchWriteOperation<GenericModel> getArchiveEventOperation({
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

  static BatchWriteOperation<GenericModel> getHideEventOperation({
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

  static BatchWriteOperation<GenericModel> getLikeEventOperation({
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

  static BatchWriteOperation<GenericModel> getReadEventOperation({
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

  static BatchWriteOperation<GenericModel> getReceiveEventOperation({
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
      GenericModel(
        data: {
          eventTag: {
            userPid: value ? DateTime.now().toUtc().toIso8601String() : '',
          },
        },
      ),
      eventsRef,
    );
  }

  static BatchWriteOperation<GenericModel> getTagEventOperation({
    required String userPid,
    required String eventTag,
    required DataRef eventsRef,
    required bool value,
  }) {
    return BatchWriteOperation(
      eventsRef,
      model: GenericModel(
        data: {
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

  static BatchWriteOperation<GenericModel> getDeleteEventOperation({
    required DataRef eventsRef,
  }) {
    return BatchWriteOperation(
      eventsRef,
      delete: true,
    );
  }

  //
  //
  //

  static Future<void> sendEvent({
    required ServiceEnvironment serviceEnvironment,
    required String senderPid,
    String? receiverPid,
    required String eventId,
    required DataRef eventsRef,
    required Model eventDef,
    required EventDefType eventDefType,
  }) async {
    final eventModel = ModelEvent(
      id: eventId,
      pids: {
        senderPid,
        if (receiverPid != null) receiverPid,
      },
      whenSent: {senderPid: DateTime.now()},
      def: eventDef.toGenericModel(),
      defType: eventDefType,
    );
    await serviceEnvironment.databaseServiceBroker.setModel(
      eventModel,
      eventsRef,
    );
  }

  static BatchWriteOperation<ModelEvent> getSendEventOperation({
    required String senderPid,
    required String receiverPid,
    required String eventId,
    required DataRef eventsRef,
    required Model eventDef,
    required EventDefType eventDefType,
  }) {
    final eventModel = ModelEvent(
      id: eventId,
      pids: {senderPid, receiverPid},
      whenSent: {senderPid: DateTime.now()},
      def: eventDef.toGenericModel(),
      defType: eventDefType,
    );
    return BatchWriteOperation<ModelEvent>(
      eventsRef,
      model: eventModel,
    );
  }
}