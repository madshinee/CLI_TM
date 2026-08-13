import 'dart:math';
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
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    this.deadline,
    this.isDone = false,
    required this.createdAt,
  });

  /// Factory constructor that creates a [Task] with sensible defaults.
  ///
  /// When [isUrgent] is `true`, an [UrgentTask] is created (optionally with
  /// a custom [urgencyLevel]). Otherwise a [RegularTask] is created.
  factory Task.create({
    required String title,
    Priority priority = Priority.medium,
    DateTime? deadline,
    bool isUrgent = false,
    int? urgencyLevel,
  }) {
    final id = _generateId();
    final createdAt = DateTime.now();

    if (isUrgent) {
      return UrgentTask(
        id: id,
        title: title,
        priority: priority,
        deadline: deadline,
        urgencyLevel: urgencyLevel ?? 3,
        createdAt: createdAt,
      );
    }

    return RegularTask(
      id: id,
      title: title,
      priority: priority,
      deadline: deadline,
      createdAt: createdAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final title = json['title'] as String;
    final priority = PriorityExtension.fromString(json['priority'] as String);
    final deadline = json['deadline'] != null
        ? DateTime.parse(json['deadline'] as String)
        : null;
    final isDone = json['isDone'] as bool? ?? false;
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final type = json['type'] as String?;

    if (type == 'urgent') {
      final urgencyLevel = json['urgencyLevel'] as int? ?? 3;
      return UrgentTask(
        id: id,
        title: title,
        priority: priority,
        deadline: deadline,
        urgencyLevel: urgencyLevel,
        createdAt: createdAt,
        isDone: isDone,
      );
    } else {
      return RegularTask(
        id: id,
        title: title,
        priority: priority,
        deadline: deadline,
        createdAt: createdAt,
        isDone: isDone,
      );
    }
  }

  /// Generates a random 8-character alphanumeric ID.
  static String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  final String id;
  final String title;
  final Priority priority;
  final DateTime? deadline;
  final bool isDone;
  final DateTime createdAt;

  Task copyWith({
    String? id,
    String? title,
    Priority? priority,
    DateTime? deadline,
    bool? isDone,
    DateTime? createdAt,
  });

  void markDone() {
    // Tasks are immutable, so markDone returns a new instance
    // This method is kept for backward compatibility but should use copyWith
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          priority == other.priority &&
          deadline == other.deadline &&
          isDone == other.isDone &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      priority.hashCode ^
      deadline.hashCode ^
      isDone.hashCode ^
      createdAt.hashCode;
}

class UrgentTask extends Task {
  UrgentTask({
    required super.id,
    required super.title,
    required super.priority,
    super.deadline,
    required this.urgencyLevel,
    DateTime? createdAt,
    super.isDone = false,
  }) : super(createdAt: createdAt ?? DateTime.now());

  final int urgencyLevel; // 1-5, where 5 is most urgent

  @override
  UrgentTask copyWith({
    String? id,
    String? title,
    Priority? priority,
    DateTime? deadline,
    bool? isDone,
    DateTime? createdAt,
    int? urgencyLevel,
  }) {
    return UrgentTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      createdAt: createdAt ?? this.createdAt,
      isDone: isDone ?? this.isDone,
    );
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is UrgentTask &&
          urgencyLevel == other.urgencyLevel;

  @override
  int get hashCode => super.hashCode ^ urgencyLevel.hashCode;
}

class RegularTask extends Task {
  RegularTask({
    required super.id,
    required super.title,
    required super.priority,
    super.deadline,
    DateTime? createdAt,
    super.isDone = false,
  }) : super(createdAt: createdAt ?? DateTime.now());

  @override
  RegularTask copyWith({
    String? id,
    String? title,
    Priority? priority,
    DateTime? deadline,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return RegularTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      isDone: isDone ?? this.isDone,
    );
  }

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
