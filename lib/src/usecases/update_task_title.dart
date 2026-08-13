import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';

/// Use case for updating the title of an existing task.
///
/// Throws [TaskNotFoundException] when no task with the given [id] exists.
/// Throws [InvalidTaskTitleException] when [newTitle] is empty or
/// whitespace-only.
class UpdateTaskTitle {
  const UpdateTaskTitle(this.repository);

  final TaskRepository repository;

  Future<void> call(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) {
      throw InvalidTaskTitleException();
    }

    final task = await repository.getById(id);
    if (task == null) {
      throw TaskNotFoundException(id);
    }

    final updatedTask = task.copyWith(title: newTitle.trim());
    await repository.update(updatedTask);
  }
}
