import 'dart:io';
import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';
import 'package:cli_task_manager/src/formatter.dart';

class TaskCli {
  TaskCli(this.service, {this.storagePath = 'tasks.json', TaskFormatter? formatter})
      : formatter = formatter ?? ConsoleTaskFormatter();

  final TaskService service;
  final String storagePath;
  final TaskFormatter formatter;

  Future<void> run(List<String> args) async {
    // Handle --help flag
    if (args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return;
    }

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
        case 'toggle':
          await _handleToggle(args);
          break;
        case 'delete':
          await _handleDelete(args);
          break;
        case 'update':
          await _handleUpdate(args);
          break;
        case 'count':
          await _handleCount(args);
          break;
        case 'help':
          _printHelp();
          break;
        default:
          print('Unknown command: $command');
          _printHelp();
      }
    } on TaskException catch (e) {
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
          case 'toggle':
            await _handleToggle(args);
            break;
          case 'delete':
            await _handleDelete(args);
            break;
          case 'update':
            await _handleUpdate(args);
            break;
          case 'count':
            await _handleCount(args);
            break;
          default:
            print('Unknown command: $command');
            print('Type "help" for available commands.');
        }
      } on TaskException catch (e) {
        print('Error: $e');
      } catch (e) {
        print('Unexpected error: $e');
      }
    }
  }

  List<String> _parseInput(String input) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
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
    var isUrgent = false;
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
    print(formatter.formatTask(task));
  }

  Future<void> _handleList(List<String> args) async {
    final sortByPriority = !args.contains('--date');
    final doneOnly = args.contains('--done');
    final pendingOnly = args.contains('--pending');

    if (doneOnly && pendingOnly) {
      print('Error: Cannot use --done and --pending together.');
      return;
    }

    final tasks = await service.listTasks(
      sortByPriority: sortByPriority,
      doneOnly: doneOnly ? true : null,
      pendingOnly: pendingOnly ? true : null,
    );

    if (tasks.isEmpty) {
      final filter = doneOnly ? 'done' : pendingOnly ? 'pending' : '';
      if (filter.isNotEmpty) {
        print('No $filter tasks found.');
      } else {
        print('No tasks found.');
      }
      return;
    }

    print(formatter.formatTaskListWithStats(tasks));
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

  Future<void> _handleToggle(List<String> args) async {
    if (args.length < 2) {
      print('Usage: toggle <task-id>');
      return;
    }

    final id = args[1];
    await service.toggleTaskDone(id);
    print('Task toggled: $id');
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

  Future<void> _handleUpdate(List<String> args) async {
    if (args.length < 3) {
      print('Usage: update <task-id> <new-title>');
      print('Example: update abc123 "New task title"');
      return;
    }

    final id = args[1];
    final newTitle = args[2];

    await service.updateTaskTitle(id, newTitle);
    print('Task title updated: $id');
  }

  Future<void> _handleCount(List<String> args) async {
    final doneOnly = args.contains('--done');
    final pendingOnly = args.contains('--pending');

    if (doneOnly && pendingOnly) {
      print('Error: Cannot use --done and --pending together.');
      return;
    }

    final count = await service.getTaskCount(
      doneOnly: doneOnly ? true : pendingOnly ? false : null,
    );

    final filter = doneOnly ? 'done' : pendingOnly ? 'pending' : 'total';
    print('$filter tasks: $count');
  }

  void _printHelp() {
    print('CLI Task Manager');
    print('---');
    print('Commands:');
    print('  add <title> <priority> [deadline] [--urgent <level>]  Add a new task');
    print('  list [--date] [--done] [--pending]                    List all tasks');
    print('  done <id>                                              Mark task as done');
    print('  toggle <id>                                            Toggle task done status');
    print('  delete <id>                                            Delete a task');
    print('  update <id> <new-title>                                Update task title');
    print('  count [--done] [--pending]                             Show task count');
    print('  help                                                   Show this help');
    print('  exit                                                   Quit the application');
    print('');
    print('Options:');
    print('  --help, -h     Show this help message');
    print('  --interactive  Start in interactive mode');
    print('  -i             Alias for --interactive');
    print('');
    print('List filters:');
    print('  --date         Sort by date instead of priority');
    print('  --done         Show only completed tasks');
    print('  --pending      Show only pending tasks');
    print('');
    print('Priorities: low, medium, high');
    print('Deadline format: YYYY-MM-DD');
    print('Urgency level: 1-5 (only with --urgent flag)');
    print('');
    print('Examples:');
    print('  dart run bin/task_cli.dart add "Buy groceries" high 2026-12-31');
    print('  dart run bin/task_cli.dart add "Fix bug" high --urgent 5');
    print('  dart run bin/task_cli.dart list --pending');
    print('  dart run bin/task_cli.dart count --done');
  }
}
