import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';

class Task {
  int? id;
  String? title;
  String? note;
  int? isCompleted;
  String? date;
  String? startTime;
  String? endTime;
  int? color;
  int? remind;
  String? repeat;

  String? eventId;
  String? recurringEventId;

  Task(
      {this.id,
      this.title,
      this.note,
      this.isCompleted,
      this.date,
      this.startTime,
      this.endTime,
      this.color,
      this.remind,
      this.repeat,
      this.eventId,
      this.recurringEventId});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'isCompleted': isCompleted,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'remind': remind,
      'repeat': repeat,
      'eventId': eventId,
      'recurringEventId': recurringEventId
    };
  }

  Task.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'].toString();
    note = json['note'].toString();
    isCompleted = json['isCompleted'];
    date = json['date'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    color = json['color'];
    remind = json['remind'];
    repeat = json['repeat'];
    eventId = json['eventId']?.toString();
    recurringEventId = json['recurringEventId'];
  }

  factory Task.fromGoogleEvent(calendar.Event event) {
    final startDateTime =
        event.start?.dateTime?.toLocal() ?? event.start?.date?.toLocal();
    final endDateTime =
        event.end?.dateTime?.toLocal() ?? event.end?.date?.toLocal();

    String? repeatRule;
    if (event.recurrence != null && event.recurrence!.isNotEmpty) {
      repeatRule = event.recurrence!.first;
    }

    return Task(
        title: event.summary ?? '',
        note: event.description ?? '',
        date: startDateTime != null
            ? DateFormat('yyyy-MM-dd').format(startDateTime)
            : '',
        startTime: startDateTime != null
            ? DateFormat('HH:mm').format(startDateTime)
            : '',
        endTime:
            endDateTime != null ? DateFormat('HH:mm').format(endDateTime) : '',
        eventId: event.id,
        color: event.colorId != null ? int.tryParse(event.colorId!) : null,
        isCompleted: 0,
        recurringEventId: event.recurringEventId,
        repeat: getRepeat(repeatRule));
  }

  calendar.Event toGoogleEvent() {
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

    final startDateTime = date != null && startTime != null
        ? dateTimeFormat.parse('$date $startTime')
        : null;

    final endDateTime = date != null && endTime != null
        ? dateTimeFormat.parse('$date $endTime')
        : null;

    return calendar.Event(
      id: eventId,
      summary: title,
      description: note,
      start: calendar.EventDateTime(
        dateTime: startDateTime,
        timeZone: 'Europe/Moscow',
      ),
      end: calendar.EventDateTime(
        dateTime: endDateTime,
        timeZone: 'Europe/Moscow',
      ),
      colorId: color?.toString(),
      recurrence: getRecurrenceRule() != null ? [getRecurrenceRule()!] : null,
    );
  }

  String? getRecurrenceRule() {
    switch (repeat) {
      case 'Daily':
        return 'RRULE:FREQ=DAILY';
      case 'Weekly':
        return 'RRULE:FREQ=WEEKLY';
      case 'Monthly':
        return 'RRULE:FREQ=MONTHLY';
      default:
        return null;
    }
  }

  static String? getRepeat(String? repeatRule) {
    if (repeatRule == null) return null;
    if (repeatRule.contains('FREQ=DAILY')) return 'Daily';
    if (repeatRule.contains('FREQ=WEEKLY')) return 'Weekly';
    if (repeatRule.contains('FREQ=MONTHLY')) return 'Monthly';
    return null;
  }
}
