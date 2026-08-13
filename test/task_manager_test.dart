import 'dart:io';
import 'package:cli_task_manager/cli_task_manager.dart';
import 'package:test/test.dart';

final threeWeeksAgo = DateTime.now().subtract(const Duration(days: 21));

void main() {
  group('Task Models', () {
    test('RegularTask can be created and marked as done', () {
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

      task.markDone();
      expect(task.isDone, true);
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

    test('markTaskDone and deleteTask work correctly', () async {
      final task = await service.addTask('Test task', Priority.low, null);
      expect(task.isDone, false);

      await service.markTaskDone(task.id);
      final updated = await repository.getById(task.id);
      expect(updated!.isDone, true);

      await service.deleteTask(task.id);
      expect(await service.getTaskCount(), 0);
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
  });
}
