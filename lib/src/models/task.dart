import 'package:cli_task_manager/src/exceptions.dart';

enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  int get sortValue {
    switch (this) {
      case Priority.low:
        return 0;
      case Priority.medium:
        return 1;
      case Priority.high:
        return 2;
    }
  }

  static Priority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        throw InvalidPriorityException(value);
    }
  }
}

abstract class Task implements Comparable<Task> {
  final String id;
  final String title;
  final Priority priority;
  final DateTime? deadline;
  bool isDone;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.deadline,
    this.isDone = false,
    required this.createdAt,
  });

  void markDone() {
    isDone = true;
  }

  Map<String, dynamic> toJson();

  @override
  int compareTo(Task other) {
    // Sort by priority first (high to low), then by deadline (earliest first)
    final priorityCompare = other.priority.sortValue.compareTo(priority.sortValue);
    if (priorityCompare != 0) return priorityCompare;
    
    final thisDeadline = deadline;
    final otherDeadline = other.deadline;
    
    if (thisDeadline == null && otherDeadline == null) return 0;
    if (thisDeadline == null) return 1;
    if (otherDeadline == null) return -1;
    
    return thisDeadline.compareTo(otherDeadline);
  }

  @override
  String toString() {
    final status = isDone ? '[x]' : '[ ]';
    final deadlineStr = deadline != null ? ' | Due: ${_formatDate(deadline!)}' : '';
    return '$status $title (${priority.displayName})$deadlineStr';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class UrgentTask extends Task {
  final int urgencyLevel; // 1-5, where 5 is most urgent

  UrgentTask({
    required String id,
    required String title,
    required Priority priority,
    DateTime? deadline,
    required this.urgencyLevel,
    DateTime? createdAt,
  }) : super(
          id: id,
          title: title,
          priority: priority,
          deadline: deadline,
          createdAt: createdAt ?? DateTime.now(),
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'type': 'urgent',
      'urgencyLevel': urgencyLevel,
    };
  }

  @override
  String toString() {
    final status = isDone ? '[x]' : '[ ]';
    final deadlineStr = deadline != null ? ' | Due: ${_formatDate(deadline!)}' : '';
    return '$status $title (${priority.displayName}, Urgency: $urgencyLevel)$deadlineStr';
  }
}

class RegularTask extends Task {
  RegularTask({
    required String id,
    required String title,
    required Priority priority,
    DateTime? deadline,
    DateTime? createdAt,
  }) : super(
          id: id,
          title: title,
          priority: priority,
          deadline: deadline,
          createdAt: createdAt ?? DateTime.now(),
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'type': 'regular',
    };
  }
}
