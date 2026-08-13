import 'dart:io';
import 'package:cli_task_manager/cli_task_manager.dart';
import 'package:test/test.dart';

final threeWeeksAgo = DateTime.now().subtract(const Duration(days: 21));

void main() {
  group('Task Models', () {
    test('RegularTask can be created and marked as done using copyWith', () {
      final task = RegularTask(
        id: 'test-1',
        title: 'Test task',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      expect(task.title, 'Test task');
      expect(task.priority, Priority.high);
      expect(task.isDone, false);
      expect(task.deadline, DateTime(2026, 8, 31));

      final updatedTask = task.copyWith(isDone: true);
      expect(updatedTask.isDone, true);
      expect(updatedTask.title, 'Test task');
    });

    test('UrgentTask can be created with urgency level', () {
      final task = UrgentTask(
        id: 'test-2',
        title: 'Urgent task',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 31),
        urgencyLevel: 5,
        createdAt: threeWeeksAgo,
      );

      expect(task.title, 'Urgent task');
      expect(task.urgencyLevel, 5);
      expect(task.priority, Priority.high);
    });

    test('Task comparison sorts by priority then deadline', () {
      final lowTask = RegularTask(
        id: 'low',
        title: 'Low priority',
        priority: Priority.low,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      final highTask = RegularTask(
        id: 'high',
        title: 'High priority',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      final mediumTask = RegularTask(
        id: 'medium',
        title: 'Medium priority',
        priority: Priority.medium,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      final tasks = [lowTask, highTask, mediumTask];
      tasks.sort();

      expect(tasks[0].id, 'high');
      expect(tasks[1].id, 'medium');
      expect(tasks[2].id, 'low');
    });

    test('Task equality works correctly', () {
      final task1 = RegularTask(
        id: 'same-id',
        title: 'Same task',
        priority: Priority.low,
        createdAt: threeWeeksAgo,
      );

      final task2 = RegularTask(
        id: 'same-id',
        title: 'Same task',
        priority: Priority.low,
        createdAt: threeWeeksAgo,
      );

      expect(task1, equals(task2));
      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('Task copyWith creates a new instance with updated values', () {
      final task = RegularTask(
        id: 'test-copy',
        title: 'Original title',
        priority: Priority.low,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      final copied = task.copyWith(
        title: 'Updated title',
        isDone: true,
      );

      expect(copied.id, task.id);
      expect(copied.title, 'Updated title');
      expect(copied.isDone, true);
      expect(copied.priority, task.priority);
      expect(copied.deadline, task.deadline);
    });

    test('Task fromJson factory creates correct task type', () {
      final json = {
        'id': 'json-test',
        'title': 'JSON Task',
        'priority': 'high',
        'deadline': '2026-08-31T00:00:00.000',
        'isDone': false,
        'createdAt': threeWeeksAgo.toIso8601String(),
        'type': 'regular',
      };

      final task = Task.fromJson(json);
      expect(task, isA<RegularTask>());
      expect(task.id, 'json-test');
      expect(task.title, 'JSON Task');
    });

    test('UrgentTask fromJson factory creates correct task type', () {
      final json = {
        'id': 'urgent-json',
        'title': 'Urgent JSON Task',
        'priority': 'high',
        'deadline': '2026-08-31T00:00:00.000',
        'isDone': true,
        'createdAt': threeWeeksAgo.toIso8601String(),
        'type': 'urgent',
        'urgencyLevel': 4,
      };

      final task = Task.fromJson(json);
      expect(task, isA<UrgentTask>());
      expect((task as UrgentTask).urgencyLevel, 4);
      expect(task.isDone, true);
    });
  });

  group('PriorityExtension', () {
    test('fromString parses valid priorities', () {
      expect(PriorityExtension.fromString('low'), Priority.low);
      expect(PriorityExtension.fromString('medium'), Priority.medium);
      expect(PriorityExtension.fromString('high'), Priority.high);
      expect(PriorityExtension.fromString('LOW'), Priority.low);
      expect(PriorityExtension.fromString('High'), Priority.high);
    });

    test('fromString throws on invalid priority', () {
      expect(() => PriorityExtension.fromString('invalid'), throwsA(isA<InvalidPriorityException>()));
    });

    test('displayName returns correct string', () {
      expect(Priority.low.displayName, 'Low');
      expect(Priority.medium.displayName, 'Medium');
      expect(Priority.high.displayName, 'High');
    });

    test('sortValue returns correct integer', () {
      expect(Priority.low.sortValue, 0);
      expect(Priority.medium.sortValue, 1);
      expect(Priority.high.sortValue, 2);
    });
  });

  group('TaskManagerService', () {
    late JsonTaskRepository repository;
    late TaskManagerService service;
    late String testFilePath;

    setUp(() {
      testFilePath = 'test_tasks_${DateTime.now().millisecondsSinceEpoch}.json';
      repository = JsonTaskRepository(testFilePath);
      service = TaskManagerService(repository);
    });

    tearDown(() async {
      try {
        final file = File(testFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors on Windows
      }
    });

    test('addTask creates task with current timestamp', () async {
      final before = DateTime.now();
      final task = await service.addTask('Timestamp test', Priority.low, null);
      final after = DateTime.now();

      expect(task.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(task.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('addTask rejects empty title', () async {
      expect(
        () => service.addTask('', Priority.low, null),
        throwsA(isA<TaskException>()),
      );
    });

    test('addTask rejects whitespace-only title', () async {
      expect(
        () => service.addTask('   ', Priority.low, null),
        throwsA(isA<TaskException>()),
      );
    });

    test('addTask validates urgency level range', () async {
      expect(
        () => service.addTask('Test', Priority.high, null, isUrgent: true, urgencyLevel: 0),
        throwsA(isA<InvalidUrgencyLevelException>()),
      );

      expect(
        () => service.addTask('Test', Priority.high, null, isUrgent: true, urgencyLevel: 6),
        throwsA(isA<InvalidUrgencyLevelException>()),
      );
    });

    test('addTask and listTasks work correctly', () async {
      await service.addTask('Low', Priority.low, null);
      await service.addTask('High', Priority.high, null);
      await service.addTask('Medium', Priority.medium, null);

      final tasks = await service.listTasks();
      expect(tasks.length, 3);
      expect(tasks[0].title, 'High');
      expect(tasks[1].title, 'Medium');
      expect(tasks[2].title, 'Low');
    });

    test('listTasks with --date sorts by creation date', () async {
      await service.addTask('First', Priority.low, null);
      await Future.delayed(const Duration(milliseconds: 10));
      await service.addTask('Second', Priority.low, null);

      final tasks = await service.listTasks(sortByPriority: false);
      expect(tasks[0].title, 'First');
      expect(tasks[1].title, 'Second');
    });

    test('listTasks filters done tasks', () async {
      final task1 = await service.addTask('Done task', Priority.low, null);
      final task2 = await service.addTask('Pending task', Priority.low, null);

      await service.markTaskDone(task1.id);

      final doneTasks = await service.listTasks(doneOnly: true);
      expect(doneTasks.length, 1);
      expect(doneTasks[0].id, task1.id);

      final pendingTasks = await service.listTasks(pendingOnly: true);
      expect(pendingTasks.length, 1);
      expect(pendingTasks[0].id, task2.id);
    });

    test('markTaskDone and deleteTask work correctly', () async {
      final task = await service.addTask('Test task', Priority.low, null);
      expect(task.isDone, false);

      await service.markTaskDone(task.id);
      final updated = await repository.getById(task.id);
      expect(updated!.isDone, true);

      await service.deleteTask(task.id);
      expect(await service.getTaskCount(), 0);
    });

    test('getTaskCount filters correctly', () async {
      final task1 = await service.addTask('Done task', Priority.low, null);
      await service.addTask('Pending task', Priority.low, null);

      await service.markTaskDone(task1.id);

      expect(await service.getTaskCount(), 2);
      expect(await service.getTaskCount(doneOnly: true), 1);
      expect(await service.getTaskCount(doneOnly: false), 1);
    });

    test('JsonTaskRepository persists and loads tasks', () async {
      final repository = JsonTaskRepository('persist_test.json');

      final task1 = RegularTask(
        id: 'persist-1',
        title: 'Persisted task',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 31),
        createdAt: threeWeeksAgo,
      );

      await repository.add(task1);

      final repository2 = JsonTaskRepository('persist_test.json');
      final loaded = await repository2.getById('persist-1');

      expect(loaded, isNotNull);
      expect(loaded!.title, 'Persisted task');
      expect(loaded.priority, Priority.high);

      final file = File('persist_test.json');
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('deleteTask throws TaskNotFoundException for non-existent id', () async {
      expect(
        () => service.deleteTask('non-existent-id'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('markTaskDone throws TaskNotFoundException for non-existent id', () async {
      expect(
        () => service.markTaskDone('non-existent-id'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('ConsoleTaskFormatter', () {
    test('formatTask returns task string representation', () {
      final formatter = ConsoleTaskFormatter();
      final task = RegularTask(
        id: 'fmt-1',
        title: 'Formatted task',
        priority: Priority.high,
        createdAt: threeWeeksAgo,
      );

      final result = formatter.formatTask(task);
      expect(result, contains('Formatted task'));
      expect(result, contains('High'));
    });

    test('formatTaskList returns formatted list', () {
      final formatter = ConsoleTaskFormatter();
      final tasks = [
        RegularTask(id: '1', title: 'Task 1', priority: Priority.low, createdAt: threeWeeksAgo),
        RegularTask(id: '2', title: 'Task 2', priority: Priority.high, createdAt: threeWeeksAgo),
      ];

      final result = formatter.formatTaskList(tasks);
      expect(result, contains('Task 1'));
      expect(result, contains('Task 2'));
      expect(result, contains('2'));
    });

    test('formatTaskListWithStats shows statistics', () {
      final formatter = ConsoleTaskFormatter();
      final tasks = [
        RegularTask(id: '1', title: 'Task 1', priority: Priority.low, createdAt: threeWeeksAgo, isDone: true),
        RegularTask(id: '2', title: 'Task 2', priority: Priority.high, createdAt: threeWeeksAgo, isDone: false),
      ];

      final result = formatter.formatTaskListWithStats(tasks);
      expect(result, contains('2 total'));
      expect(result, contains('1 pending'));
      expect(result, contains('1 done'));
    });
  });

  group('TaskCli', () {
    test('--help flag triggers help output', () async {
      final repository = JsonTaskRepository('help_test.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'help_test.json');

      // Test that --help doesn't throw and processes correctly
      await cli.run(['--help']);
      // If we get here without exception, the test passes
    });

    test('-h flag triggers help output', () async {
      final repository = JsonTaskRepository('help_test2.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'help_test2.json');

      await cli.run(['-h']);
    });

    test('unknown command shows error', () async {
      final repository = JsonTaskRepository('unknown_test.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'unknown_test.json');

      await cli.run(['unknown']);
    });

    test('count command works', () async {
      final repository = JsonTaskRepository('count_test.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'count_test.json');

      await service.addTask('Task 1', Priority.low, null);
      await service.addTask('Task 2', Priority.high, null);

      await cli.run(['count']);
    });

    test('list with --done filter works', () async {
      final repository = JsonTaskRepository('list_done_test.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'list_done_test.json');

      final task = await service.addTask('Done task', Priority.low, null);
      await service.markTaskDone(task.id);

      await cli.run(['list', '--done']);
    });

    test('list with --pending filter works', () async {
      final repository = JsonTaskRepository('list_pending_test.json');
      final service = TaskManagerService(repository);
      final cli = TaskCli(service, storagePath: 'list_pending_test.json');

      await service.addTask('Pending task', Priority.low, null);

      await cli.run(['list', '--pending']);
    });
  });
}
