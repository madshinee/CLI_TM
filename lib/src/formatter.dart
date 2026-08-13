import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';

class ConsoleTaskFormatter implements TaskFormatter {
  @override
  String formatTask(Task task) {
    return task.toString();
  }

  @override
  String formatTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return 'No tasks found.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Tasks (${tasks.length}):');
    buffer.writeln('---');

    for (final task in tasks) {
      buffer.writeln(formatTask(task));
    }

    return buffer.toString();
  }

  @override
  String formatTaskListWithStats(List<Task> tasks) {
    if (tasks.isEmpty) {
      return 'No tasks found.';
    }

    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final pending = total - done;

    final buffer = StringBuffer();
    buffer.writeln('Tasks ($total total, $pending pending, $done done):');
    buffer.writeln('---');

    for (final task in tasks) {
      buffer.writeln(formatTask(task));
    }

    return buffer.toString();
  }
}
