import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';
import 'package:cli_task_manager/src/usecases/add_task.dart';
import 'package:cli_task_manager/src/usecases/delete_task.dart';
import 'package:cli_task_manager/src/usecases/list_tasks.dart';
import 'package:cli_task_manager/src/usecases/toggle_task_done.dart';
import 'package:cli_task_manager/src/usecases/update_task_title.dart';

/// Service layer that orchestrates task operations by delegating to
/// dedicated use-case classes.
class TaskManagerService implements TaskService {
  TaskManagerService(this.repository) {
    _addTask = AddTask(repository);
    _listTasks = ListTasks(repository);
    _toggleTaskDone = ToggleTaskDone(repository);
    _deleteTask = DeleteTask(repository);
    _updateTaskTitle = UpdateTaskTitle(repository);
  }

  final TaskRepository repository;
  late final AddTask _addTask;
  late final ListTasks _listTasks;
  late final ToggleTaskDone _toggleTaskDone;
  late final DeleteTask _deleteTask;
  late final UpdateTaskTitle _updateTaskTitle;

  @override
  Future<Task> addTask(
    String title,
    Priority priority,
    DateTime? deadline, {
    bool isUrgent = false,
    int? urgencyLevel,
  }) {
    return _addTask(
      title: title,
      priority: priority,
      deadline: deadline,
      isUrgent: isUrgent,
      urgencyLevel: urgencyLevel,
    );
  }

  @override
  Future<void> markTaskDone(String id) async {
    final task = await repository.getById(id);
    if (task == null) {
      throw TaskNotFoundException(id);
    }
    final updatedTask = task.copyWith(isDone: true);
    await repository.update(updatedTask);
  }

  @override
  Future<void> toggleTaskDone(String id) {
    return _toggleTaskDone(id);
  }

  @override
  Future<void> deleteTask(String id) {
    return _deleteTask(id);
  }

  @override
  Future<void> updateTaskTitle(String id, String newTitle) {
    return _updateTaskTitle(id, newTitle);
  }

  @override
  Future<List<Task>> listTasks({bool sortByPriority = true, bool? doneOnly, bool? pendingOnly}) {
    return _listTasks(
      sortByPriority: sortByPriority,
      doneOnly: doneOnly,
      pendingOnly: pendingOnly,
    );
  }

  @override
  Future<int> getTaskCount({bool? doneOnly}) async {
    if (doneOnly == true) {
      final tasks = await repository.getAll();
      return tasks.where((t) => t.isDone).length;
    } else if (doneOnly == false) {
      final tasks = await repository.getAll();
      return tasks.where((t) => !t.isDone).length;
    }
    return repository.getCount();
  }
}
