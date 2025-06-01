import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/db/google_calendar_helper.dart';
import 'package:todo/db/db_helper.dart';
import 'package:todo/models/task.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = <Task>[].obs;
  RxList<Task> allTasksList = <Task>[].obs;

  final GoogleCalendarHelper calendarHelper;

  TaskController(this.calendarHelper);

  Future<int> addTask({Task? task}) async {
    await calendarHelper.insert(task!);

    return DBHelper.insert(task);
  }

  Future<void> getTasks() async {
    final List<Map<String, dynamic>> tasks = await DBHelper.query();
    allTasksList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
  }

  void filterTasksByDate(DateTime selectedDate) {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    taskList.assignAll(
        allTasksList.where((task) => task.date == dateString).toList());
  }

  Future<void> deleteTasks(Task task) async {
    await calendarHelper.delete(task);

    await DBHelper.delete(task);
    await getTasks();
  }

  Future<void> deleteTasksByDate() async {
    for (var task in taskList) {
      await calendarHelper.delete(task);
      await DBHelper.delete(task);
    }

    await getTasks();
  }

  Future<void> deleteAllTasks() async {
    await DBHelper.deleteAll();
    await getTasks();
  }

  Future<void> markTaskAsCompleted(Task task) async {
    task.isCompleted = 1;

    await DBHelper.mark(task.id!);

    await getTasks();
  }

  Future<void> syncFromGoogleCalendar() async {
    final googleTasks = await calendarHelper.getTasks();

    final localTasks = await DBHelper.query();
    final Map<String, int> completedStatusByEventId = {
      for (var taskData in localTasks)
        if (taskData['eventId'] != null && taskData['isCompleted'] != null)
          taskData['eventId'] as String: taskData['isCompleted'] as int,
    };

    await DBHelper.deleteAll();

    for (final task in googleTasks) {
      final completedStatus = completedStatusByEventId[task.eventId] ?? 0;
      final taskWithStatus = Task(
        title: task.title,
        note: task.note,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        eventId: task.eventId,
        color: task.color,
        repeat: task.repeat,
        recurringEventId: task.recurringEventId,
        isCompleted: completedStatus,
      );
      await DBHelper.insert(taskWithStatus);
    }

    await getTasks();
  }

  Future<void> updateTask(Task task) async {
    await calendarHelper.update(task);
    await DBHelper.update(task);

    for (int i = 0; i < allTasksList.length; i++) {
      if (allTasksList[i].eventId == task.eventId) {
        allTasksList[i] = Task(
          id: allTasksList[i].id,
          title: task.title,
          note: task.note,
          date: task.date,
          startTime: task.startTime,
          endTime: task.endTime,
          remind: task.remind,
          repeat: task.repeat,
          color: task.color,
          isCompleted: task.isCompleted,
          eventId: task.eventId,
          recurringEventId: task.recurringEventId,
        );
      }
    }

    allTasksList.refresh();
  }
}
