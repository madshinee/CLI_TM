import 'dart:io';
import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';
import 'package:cli_task_manager/src/service.dart';

class TaskCli {
  final TaskService service;
  final String storagePath;

  TaskCli(this.service, {this.storagePath = 'tasks.json'});

  Future<void> run(List<String> args) async {
    final interactive = args.isEmpty || args.contains('--interactive') || args.contains('-i');

    if (interactive) {
      await _runInteractive();
      return;
    }

    final command = args[0].toLowerCase();

    try {
      switch (command) {
        case 'add':
          await _handleAdd(args);
          break;
        case 'list':
          await _handleList(args);
          break;
        case 'done':
          await _handleDone(args);
          break;
        case 'delete':
          await _handleDelete(args);
          break;
        case 'help':
          _printHelp();
          break;
        default:
          print('Unknown command: $command');
          _printHelp();
      }
    } on TaskManagerException catch (e) {
      print('Error: $e');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  Future<void> _runInteractive() async {
    print('CLI Task Manager');
    print('Type "help" for available commands, "exit" to quit.');
    print('---');

    while (true) {
      stdout.write('task-cli> ');
      final input = stdin.readLineSync();

      if (input == null) break;

      final trimmed = input.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.toLowerCase() == 'exit' || trimmed.toLowerCase() == 'quit') {
        print('Goodbye!');
        break;
      }

      if (trimmed.toLowerCase() == 'help') {
        _printHelp();
        continue;
      }

      final args = _parseInput(trimmed);
      if (args.isEmpty) continue;

      final command = args[0].toLowerCase();

      try {
        switch (command) {
          case 'add':
            await _handleAdd(args);
            break;
          case 'list':
            await _handleList(args);
            break;
          case 'done':
            await _handleDone(args);
            break;
          case 'delete':
            await _handleDelete(args);
            break;
          default:
            print('Unknown command: $command');
            print('Type "help" for available commands.');
        }
      } on TaskManagerException catch (e) {
        print('Error: $e');
      } catch (e) {
        print('Unexpected error: $e');
      }
    }
  }

  List<String> _parseInput(String input) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }

    return result;
  }

  Future<void> _handleAdd(List<String> args) async {
    if (args.length < 3) {
      print('Usage: add <title> <priority> [deadline] [--urgent <level>]');
      print('Example: add "Buy groceries" high 2024-12-31');
      print('Example: add "Fix bug" high --urgent 5');
      return;
    }

    final title = args[1];
    final priorityStr = args[2];
    DateTime? deadline;
    bool isUrgent = false;
    int? urgencyLevel;

    // Parse deadline if present (format: YYYY-MM-DD)
    if (args.length >= 4 && !args[3].startsWith('--')) {
      try {
        deadline = DateTime.parse(args[3]);
      } catch (e) {
        print('Invalid deadline format. Use YYYY-MM-DD');
        return;
      }
    }

    // Check for --urgent flag
    final urgentIndex = args.indexWhere((arg) => arg == '--urgent');
    if (urgentIndex != -1 && urgentIndex + 1 < args.length) {
      isUrgent = true;
      try {
        urgencyLevel = int.parse(args[urgentIndex + 1]);
      } catch (e) {
        print('Invalid urgency level. Must be a number between 1 and 5.');
        return;
      }
    }

    Priority priority;
    try {
      priority = PriorityExtension.fromString(priorityStr);
    } on InvalidPriorityException catch (e) {
      print('Error: $e');
      return;
    }

    final task = await service.addTask(
      title,
      priority,
      deadline,
      isUrgent: isUrgent,
      urgencyLevel: urgencyLevel,
    );

    print('Task added: ${task.id}');
    print(task.toString());
  }

  Future<void> _handleList(List<String> args) async {
    final sortByPriority = !args.contains('--date');
    final tasks = await service.listTasks(sortByPriority: sortByPriority);

    if (tasks.isEmpty) {
      print('No tasks found.');
      return;
    }

    print('Tasks (${tasks.length}):');
    print('---');
    for (final task in tasks) {
      print(task.toString());
    }
  }

  Future<void> _handleDone(List<String> args) async {
    if (args.length < 2) {
      print('Usage: done <task-id>');
      return;
    }

    final id = args[1];
    await service.markTaskDone(id);
    print('Task marked as done: $id');
  }

  Future<void> _handleDelete(List<String> args) async {
    if (args.length < 2) {
      print('Usage: delete <task-id>');
      return;
    }

    final id = args[1];
    await service.deleteTask(id);
    print('Task deleted: $id');
  }

  void _printHelp() {
    print('CLI Task Manager');
    print('---');
    print('Commands:');
    print('  add <title> <priority> [deadline] [--urgent <level>]  Add a new task');
    print('  list [--date]                                          List all tasks');
    print('  done <id>                                              Mark task as done');
    print('  delete <id>                                            Delete a task');
    print('  help                                                   Show this help');
    print('  exit                                                   Quit the application');
    print('');
    print('Priorities: low, medium, high');
    print('Deadline format: YYYY-MM-DD');
    print('Urgency level: 1-5 (only with --urgent flag)');
  }
}
