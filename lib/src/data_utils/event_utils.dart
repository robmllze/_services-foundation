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
    required String? targetPid,
    Set<TopicType> topics = const {},
    bool includeArchived = false,
    bool includeHidden = false,
    bool includeRead = false,
  }) {
    return eventPool?.nullIfEmpty?.where(
          (e) {
            return (topics.isEmpty || topics.contains(e.topic)) &&
                (!includeHidden && !e.isHiddenBy(targetPid)) &&
                (!includeArchived && !e.isArchivedBy(targetPid)) &&
                (!includeRead && !e.isReadBy(targetPid));
          },
        ).length ??
        0;
  }

  //
  //
  //

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      by: by,
      regsKey: ModelEvent.K_ARCHIVED_REGS,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      by: by,
      regsKey: ModelEvent.K_HIDDEN_REGS,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      by: by,
      regsKey: ModelEvent.K_LIKED_REGS,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      by: by,
      regsKey: ModelEvent.K_READ_REGS,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      by: by,
      regsKey: ModelEvent.K_RECEIVED_REGS,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String by,
    required String regsKey,
    required DataRef eventsRef,
    required bool enabled,
  }) async {
    serviceEnvironment.databaseServiceBroker.runTransaction((tr) async {
      final event = await tr.read(eventsRef, ModelEvent.fromJsonOrNull);
      if (event != null) {
        tagEventTrUpdate(
          enabled: enabled,
          event: event,
          regsKey: regsKey,
          tr: tr,
          by: by,
        );
      }
    });
  }

  static void tagEventTrUpdate({
    required TransactionInterface tr,
    required ModelEvent event,
    required String by,
    required String regsKey,
    required bool enabled,
  }) {
    final eventData = event.toJson();
    final registrations = letAs<List>(eventData[regsKey])
        ?.map((e) => letAsJMapOrNull(e))
        .map((e) => ModelRegistration.fromJsonOrNull(e))
        .nonNulls
        .toList();
    if (registrations != null && registrations.isNotEmpty) {
      final index = registrations.indexWhere((e) => e.id == by);
      if (index != -1) {
        registrations[index]
          ..at = DateTime.now()
          ..enabled = enabled;
        tr.overwrite(
          DataModel(
            data: {
              ...eventData,
              regsKey: registrations.map((e) => e.toJson()).toList(),
            },
          ),
        );
      }
    }
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
      createdReg: ModelRegistration(
        by: senderPid,
        at: DateTime.now(),
      ),
      body: DataModel(data: body.toJson()),
      topic: topic,
    );
    return CreateOrUpdateOperation(model: eventModel);
  }
}
