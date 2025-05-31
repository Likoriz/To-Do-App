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

  // void filterTasksByDate(DateTime selectedDate) {
  //   final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

  //   taskList.assignAll(allTasksList.where((task) {
  //     if (task.date == dateString) return true;

  //     if (task.repeat == 'Daily') return true;

  //     if (task.repeat == 'Weekly') {
  //       final taskDate = DateTime.parse(task.date!);
  //       return taskDate.weekday == selectedDate.weekday;
  //     }

  //     if (task.repeat == 'Monthly') {
  //       final taskDate = DateTime.parse(task.date!);
  //       return taskDate.day == selectedDate.day;
  //     }

  //     return false;
  //   }).toList());
  // }

  Future<void> deleteTasks(Task task) async {
    await calendarHelper.delete(task);

    await DBHelper.delete(task);
    await getTasks();
  }

  Future<void> deleteAllTasks() async {
    await DBHelper.deleteAll();
    await getTasks();
  }

  Future<void> markTaskAsCompleted(int id) async {
    await calendarHelper.update(id);

    await DBHelper.update(id);
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
        isCompleted: completedStatus,
      );
      await DBHelper.insert(taskWithStatus);
    }

    await getTasks();
  }
}
