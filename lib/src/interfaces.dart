import 'package:cli_task_manager/src/models/task.dart';

abstract class TaskRepository {
  Future<void> add(Task task);
  Future<void> delete(String id);
  Future<Task?> getById(String id);
  Future<List<Task>> getAll();
  Future<void> update(Task task);
  Future<int> getCount();
}

abstract class TaskService {
  Future<Task> addTask(String title, Priority priority, DateTime? deadline, {bool isUrgent = false, int? urgencyLevel});
  Future<void> markTaskDone(String id);
  Future<void> deleteTask(String id);
  Future<List<Task>> listTasks({bool sortByPriority = true});
  Future<int> getTaskCount();
}

abstract class TaskFormatter {
  String formatTask(Task task);
  String formatTaskList(List<Task> tasks);
}
