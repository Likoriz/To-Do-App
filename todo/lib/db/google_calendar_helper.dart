import 'package:todo/db/db_helper.dart';
import 'package:todo/models/task.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarHelper {
  final calendar.CalendarApi _api;

  String calendarId;

  GoogleCalendarHelper(this._api, this.calendarId);

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
          timeMin: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
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

  Future<void> update(Task task) async {
    final originalTask = await DBHelper.getTaskById(task.id!);

    if (originalTask == null) {
      print('Original task not found. Aborting update.');
      return;
    }

    await delete(originalTask);

    calendar.Event newEvent = calendar.Event()
      ..summary = task.title
      ..description = task.note
      ..colorId = task.color.toString()
      ..start = calendar.EventDateTime(
        dateTime: _combineDateAndTime(task.date, task.startTime)?.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: _combineDateAndTime(task.date, task.endTime)?.toUtc(),
        timeZone: 'UTC',
      );

    final isRecurring = task.repeat != null && task.repeat != 'None';
    if (isRecurring) {
      final rule = task.getRecurrenceRule();
      if (rule != null) {
        newEvent.recurrence = [rule];
      }
    }

    final inserted = await _api.events.insert(newEvent, calendarId.trim());

    task.eventId = inserted.id;
    task.recurringEventId = inserted.recurringEventId;
    await DBHelper.update(task);
  }

  DateTime? _combineDateAndTime(String? date, String? time) {
    if (date == null || time == null) return null;
    try {
      final datePart = DateTime.parse(date);
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(
          datePart.year, datePart.month, datePart.day, hour, minute);
    } catch (e) {
      print('Error while parsing date and time: $e');
      return null;
    }
  }
}
