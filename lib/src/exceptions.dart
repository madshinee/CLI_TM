class TaskManagerException implements Exception {
  final String message;
  final dynamic cause;

  TaskManagerException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'TaskManagerException: $message\nCaused by: $cause';
    }
    return 'TaskManagerException: $message';
  }
}

class TaskNotFoundException extends TaskManagerException {
  final String taskId;

  TaskNotFoundException(this.taskId)
      : super('Task with ID "$taskId" not found');
}

class InvalidPriorityException extends TaskManagerException {
  final String value;

  InvalidPriorityException(this.value)
      : super('Invalid priority value: "$value". Must be low, medium, or high.');
}

class InvalidUrgencyLevelException extends TaskManagerException {
  final int level;

  InvalidUrgencyLevelException(this.level)
      : super('Invalid urgency level: $level. Must be between 1 and 5.');
}

class PersistenceException extends TaskManagerException {
  PersistenceException(String message, [dynamic cause])
      : super(message, cause);
}

class RepositoryException extends TaskManagerException {
  RepositoryException(String message, [dynamic cause])
      : super(message, cause);
}
