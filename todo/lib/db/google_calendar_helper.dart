import 'package:todo/models/task.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarHelper {
  final calendar.CalendarApi _api;

  String calendarId;

  GoogleCalendarHelper(this._api, this.calendarId);

  // Future<List<Task>> getTasks() async {
  //   final events = await _api.events.list(calendarId.trim());
  //   return events.items!
  //       .where((e) => e.status != 'cancelled')
  //       .map((e) => Task.fromGoogleEvent(e))
  //       .toList();
  // }

  Future<List<Task>> getTasks() async {
    final events = await _api.events.list(calendarId.trim());
    final List<Task> allTasks = [];

    for (var event in events.items!) {
      if (event.status == 'cancelled') continue;

      if (event.recurrence != null &&
          event.recurrence!.isNotEmpty &&
          event.id != null) {
        final instances = await _api.events.instances(
          calendarId.trim(),
          event.id!,
          timeMin: DateTime.now().toUtc(),
          timeMax: DateTime.now().add(const Duration(days: 60)).toUtc(),
        );

        for (var instance in instances.items!) {
          final task = Task.fromGoogleEvent(instance);
          task.repeat = Task.getRepeat(event.recurrence!.first);

          task.recurringEventId = instance.recurringEventId;

          allTasks.add(task);
        }
      } else {
        final task = Task.fromGoogleEvent(event);
        final taskDate = DateTime.parse(task.date.toString());
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);

        if (!taskDate.isBefore(today)) {
          allTasks.add(task);
        }
      }
    }

    return allTasks;
  }

  Future<void> insert(Task task) async {
    final event = task.toGoogleEvent();

    await _api.events.insert(event, calendarId);
  }

  Future<void> delete(Task task) async {
    final String? targetId = task.recurringEventId ?? task.eventId;
    if (targetId == null) return;

    await _api.events.delete(calendarId.trim(), targetId);
  }

  Future<void> update(int id) async {}
}
