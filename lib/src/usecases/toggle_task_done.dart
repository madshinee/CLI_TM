import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';

/// Use case for toggling the `isDone` flag of an existing task.
///
/// Throws [TaskNotFoundException] when no task with the given [id] exists.
class ToggleTaskDone {
  const ToggleTaskDone(this.repository);

  final TaskRepository repository;

  Future<void> call(String id) async {
    final task = await repository.getById(id);
    if (task == null) {
      throw TaskNotFoundException(id);
    }
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await repository.update(updatedTask);
  }
}
