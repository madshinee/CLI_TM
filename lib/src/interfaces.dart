import 'package:cli_task_manager/src/models/task.dart';
import 'package:cli_task_manager/src/repositories/repository.dart';

/// Task-specific repository interface extending the generic [Repository<Task>].
abstract class TaskRepository extends Repository<Task> {
  Future<Task?> getById(String id);
  Future<int> getCount();
}

abstract class TaskService {
  Future<Task> addTask(String title, Priority priority, DateTime? deadline, {bool isUrgent = false, int? urgencyLevel});
  Future<void> markTaskDone(String id);
  Future<void> toggleTaskDone(String id);
  Future<void> deleteTask(String id);
  Future<void> updateTaskTitle(String id, String newTitle);
  Future<List<Task>> listTasks({bool sortByPriority = true, bool? doneOnly, bool? pendingOnly});
  Future<int> getTaskCount({bool? doneOnly});
}

abstract class TaskFormatter {
  String formatTask(Task task);
  String formatTaskList(List<Task> tasks);
  String formatTaskListWithStats(List<Task> tasks);
}
