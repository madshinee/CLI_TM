import 'package:cli_task_manager/src/interfaces.dart';

/// Use case for deleting a task by its ID.
///
/// Delegates to the repository's [TaskRepository.delete], which throws
/// [TaskNotFoundException] when the ID does not exist.
class DeleteTask {
  const DeleteTask(this.repository);

  final TaskRepository repository;

  Future<void> call(String id) async {
    await repository.delete(id);
  }
}
