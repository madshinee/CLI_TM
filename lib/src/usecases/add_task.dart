import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';

/// Use case for adding a new task.
///
/// Throws [InvalidTaskTitleException] when the title is empty or
/// whitespace-only. Throws [InvalidUrgencyLevelException] when an
/// urgency level outside the 1–5 range is supplied for an urgent task.
class AddTask {
  const AddTask(this.repository);

  final TaskRepository repository;

  Future<Task> call({
    required String title,
    Priority priority = Priority.medium,
    DateTime? deadline,
    bool isUrgent = false,
    int? urgencyLevel,
  }) async {
    if (title.trim().isEmpty) {
      throw InvalidTaskTitleException();
    }

    if (isUrgent && urgencyLevel != null) {
      if (urgencyLevel < 1 || urgencyLevel > 5) {
        throw InvalidUrgencyLevelException(urgencyLevel);
      }
    }

    final task = Task.create(
      title: title.trim(),
      priority: priority,
      deadline: deadline,
      isUrgent: isUrgent,
      urgencyLevel: urgencyLevel,
    );

    await repository.add(task);
    return task;
  }
}
