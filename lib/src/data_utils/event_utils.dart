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
  }) {
    if (targetPid == null || targetPid.isEmpty) return 0;
    if (eventPool == null || eventPool.isEmpty) return 0;
    return eventPool.where(
      (e) {
        // 1. Don't count events created by the target user.
        if (e.createdGReg?.registeredBy == targetPid) {
          return false;
        }

        // 2. Don't count  events that are not of the specified topics.
        if (topics.isNotEmpty && !topics.contains(TopicType.values.valueOf(e.contentType?.name))) {
          return false;
        }

        // 3. Don't count  events that are read, archived, or hidden by the target user.
        try {
          if (e.isReadBy(targetPid)) {
            return false;
          }
          if (e.isArchivedBy(targetPid)) {
            return false;
          }
          if (e.isHiddenBy(targetPid)) {
            return false;
          }
        } catch (_) {
          return false;
        }

        // 4. Count any other events.
        return true;
      },
    ).length;
  }

  //
  //
  //

  static Future<void> sendMessage({
    required String message,
    required String senderPid,
    required String relationshipId,
    required FunctionsServiceInterface functionsServiceBroker,
    required RelationshipService relationshipService,
  }) async {
    if (message.trim().isNotEmpty) {
      final newEventId = IdUtils.newEventId();
      final eventService =
          relationshipService.messageEventServices.pEventServicePool.value[relationshipId]!;
      final eventsRef = Schema.relationshipMessageEventsRef(
        relationshipId: relationshipId,
        eventId: newEventId,
      );
      final eventModel = ModelEvent(
        ref: eventsRef,
        id: eventsRef.id!,
        memberPids: {
          senderPid,
        },
        createdGReg: ModelRegistration(
          registeredBy: senderPid,
          registeredAt: DateTime.now(),
        ),
        content: Model.of(
          ModelMessageContent(
            senderPid: senderPid,
            relationshipId: relationshipId,
            message: message,
          ),
        ),
        contentType: TopicType.MESSAGE.toEnumModel(),
      );
      await Future.wait(
        [
          eventService.addEvent(eventModel),
          functionsServiceBroker.sendMessage(
            senderPid: senderPid,
            relationshipId: relationshipId,
            message: message,
            newEventId: newEventId,
          ),
        ],
      );
    }
  }

  //
  //
  //

  static Future<void> archiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      registeredBy: registeredBy,
      regsKey: ModelEventFields.archivedRegs.name,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> hideEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      registeredBy: registeredBy,
      regsKey: ModelEventFields.hiddenRegs.name,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> likeEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      registeredBy: registeredBy,
      regsKey: ModelEventFields.likedRegs.name,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> readEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      registeredBy: registeredBy,
      regsKey: ModelEventFields.readRegs.name,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> receiveEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
    required DataRef eventsRef,
    bool enabled = true,
  }) async {
    await tagEvent(
      serviceEnvironment: serviceEnvironment,
      registeredBy: registeredBy,
      regsKey: ModelEventFields.receivedRegs.name,
      eventsRef: eventsRef,
      enabled: enabled,
    );
  }

  //
  //
  //

  static Future<void> tagEvent({
    required ServiceEnvironment serviceEnvironment,
    required String registeredBy,
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
          registeredBy: registeredBy,
        );
      }
    });
  }

  static void tagEventTrUpdate({
    required TransactionInterface tr,
    required ModelEvent event,
    required String registeredBy,
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
      final index = registrations.indexWhere((e) => e.registeredBy == registeredBy);
      if (index != -1) {
        final temp = registrations[index];
        registrations[index] = temp.copyWith(
          ModelRegistration(
            registeredAt: DateTime.now(),
            enabled: enabled,
          ),
        );
        tr.overwrite(
          Model(
            {
              ...eventData,
              regsKey: registrations.map((e) => e.toJson()).toList(),
            },
          ),
        );
      }
    } else {
      final update = Model(
        {
          ...eventData,
          regsKey: [
            ModelRegistration(
              registeredBy: registeredBy,
              registeredAt: DateTime.now(),
              enabled: enabled,
            ).toJson(),
          ],
        },
      );
      tr.overwrite(update);
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
    required DataRef eventsRef,
    required ModelMessageContent message,
    required TopicType topic,
  }) async {
    await getSendEventOperation(
      senderPid: senderPid,
      receiverPid: receiverPid,
      eventsRef: eventsRef,
      content: message,
      topic: topic,
    ).execute(serviceEnvironment);
  }

  //
  //
  //

  static CreateOrUpdateOperation getSendEventOperation({
    required String senderPid,
    String? receiverPid,
    required DataRef eventsRef,
    required Model content,
    required TopicType topic,
  }) {
    final eventModel = ModelEvent(
      ref: eventsRef,
      id: eventsRef.id!,
      memberPids: {
        senderPid,
        if (receiverPid != null) receiverPid,
      },
      createdGReg: ModelRegistration(
        registeredBy: senderPid,
        registeredAt: DateTime.now(),
      ),
      content: Model(content.toJson()),
      contentType: topic.toEnumModel(),
    );
    return CreateOrUpdateOperation(model: eventModel);
  }
}
