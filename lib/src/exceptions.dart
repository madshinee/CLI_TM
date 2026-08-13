/// Base exception for all task-related errors.
class TaskException implements Exception {
  const TaskException(this.message, [this.cause]);

  final String message;
  final dynamic cause;

  @override
  String toString() {
    if (cause != null) {
      return 'TaskException: $message\nCaused by: $cause';
    }
    return 'TaskException: $message';
  }
}

/// Thrown when a task with a given ID cannot be found.
class TaskNotFoundException extends TaskException {
  const TaskNotFoundException(this.taskId)
      : super('Task with ID "$taskId" not found');

  final String taskId;
}

/// Thrown when an invalid priority value is provided.
class InvalidPriorityException extends TaskException {
  const InvalidPriorityException(this.value)
      : super('Invalid priority value: "$value". Must be low, medium, or high.');

  final String value;
}

/// Thrown when an invalid urgency level is provided.
class InvalidUrgencyLevelException extends TaskException {
  const InvalidUrgencyLevelException(this.level)
      : super('Invalid urgency level: $level. Must be between 1 and 5.');

  final int level;
}

/// Thrown when a task title is empty or whitespace-only.
class InvalidTaskTitleException extends TaskException {
  InvalidTaskTitleException() : super('Task title cannot be empty');
}

/// Thrown when a persistence operation fails.
class PersistenceException extends TaskException {
  PersistenceException(super.message, [super.cause]);
}

/// Thrown when a repository operation fails.
class RepositoryException extends TaskException {
  RepositoryException(super.message, [super.cause]);
}
