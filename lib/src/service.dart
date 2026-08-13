import 'dart:math';
import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';

class TaskManagerService implements TaskService {
  final TaskRepository repository;

  TaskManagerService(this.repository);

  @override
  Future<Task> addTask(
    String title,
    Priority priority,
    DateTime? deadline, {
    bool isUrgent = false,
    int? urgencyLevel,
  }) async {
    if (title.trim().isEmpty) {
      throw TaskManagerException('Task title cannot be empty');
    }

    if (isUrgent && urgencyLevel != null) {
      if (urgencyLevel < 1 || urgencyLevel > 5) {
        throw InvalidUrgencyLevelException(urgencyLevel);
      }
    }

    final id = _generateId();
    final createdAt = DateTime.now();

    Task task;
    if (isUrgent) {
      task = UrgentTask(
        id: id,
        title: title.trim(),
        priority: priority,
        deadline: deadline,
        urgencyLevel: urgencyLevel ?? 3,
        createdAt: createdAt,
      );
    } else {
      task = RegularTask(
        id: id,
        title: title.trim(),
        priority: priority,
        deadline: deadline,
        createdAt: createdAt,
      );
    }

    await repository.add(task);
    return task;
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
  Future<void> deleteTask(String id) async {
    await repository.delete(id);
  }

  @override
  Future<List<Task>> listTasks({bool sortByPriority = true, bool? doneOnly, bool? pendingOnly}) async {
    final tasks = await repository.getAll();
    var list = tasks.toList();

    // Apply filters
    if (doneOnly == true) {
      list = list.where((t) => t.isDone).toList();
    } else if (pendingOnly == true) {
      list = list.where((t) => !t.isDone).toList();
    }

    if (sortByPriority) {
      list.sort();
    } else {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return list;
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
    return await repository.getCount();
  }

  String _generateId() {
    final random = Random();
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
