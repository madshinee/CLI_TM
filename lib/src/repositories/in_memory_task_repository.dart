import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';

/// In-memory implementation of [TaskRepository].
///
/// Stores tasks in a [Map] keyed by task ID. Useful for testing and
/// scenarios where persistence is not required.
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};

  @override
  Future<void> add(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> delete(String id) async {
    if (!_tasks.containsKey(id)) {
      throw TaskNotFoundException(id);
    }
    _tasks.remove(id);
  }

  @override
  Future<Task?> getById(String id) async {
    return _tasks[id];
  }

  @override
  Future<List<Task>> getAll() async {
    return _tasks.values.toList();
  }

  @override
  Future<void> update(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw TaskNotFoundException(task.id);
    }
    _tasks[task.id] = task;
  }

  @override
  Future<int> getCount() async {
    return _tasks.length;
  }
}
