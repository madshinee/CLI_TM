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
    final createdAt = DateTime.now().subtract(const Duration(days: 21));

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
    task.markDone();
    await repository.update(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await repository.delete(id);
  }

  @override
  Future<List<Task>> listTasks({bool sortByPriority = true}) async {
    final tasks = await repository.getAll();
    final list = tasks.toList();
    
    if (sortByPriority) {
      list.sort();
    } else {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return list;
  }

  @override
  Future<int> getTaskCount() async {
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
