import 'dart:io';
import 'package:cli_task_manager/cli_task_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Task.create()', () {
    test('creates a RegularTask with correct default fields', () {
      final task = Task.create(title: 'My task');

      expect(task, isA<RegularTask>());
      expect(task.title, 'My task');
      expect(task.priority, Priority.medium);
      expect(task.isDone, false);
      expect(task.deadline, isNull);
      expect(task.id, isNotEmpty);
      expect(task.createdAt, isNotNull);
    });

    test('creates an UrgentTask when isUrgent is true', () {
      final task = Task.create(
        title: 'Urgent task',
        isUrgent: true,
        urgencyLevel: 5,
      );

      expect(task, isA<UrgentTask>());
      expect(task.title, 'Urgent task');
      expect((task as UrgentTask).urgencyLevel, 5);
    });

    test('creates an UrgentTask with default urgency level when not specified', () {
      final task = Task.create(title: 'Urgent task', isUrgent: true);

      expect(task, isA<UrgentTask>());
      expect((task as UrgentTask).urgencyLevel, 3);
    });

    test('creates a task with custom priority and deadline', () {
      final deadline = DateTime(2026, 12, 31);
      final task = Task.create(
        title: 'Planned task',
        priority: Priority.high,
        deadline: deadline,
      );

      expect(task.title, 'Planned task');
      expect(task.priority, Priority.high);
      expect(task.deadline, deadline);
    });
  });

  group('Task.copyWith()', () {
    test('returns a new instance with updated values', () {
      final task = RegularTask(
        id: 'test-1',
        title: 'Original',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      final copied = task.copyWith(
        title: 'Updated',
        isDone: true,
        priority: Priority.high,
      );

      expect(copied, isNot(same(task)));
      expect(copied.id, task.id);
      expect(copied.title, 'Updated');
      expect(copied.isDone, true);
      expect(copied.priority, Priority.high);
      expect(copied.createdAt, task.createdAt);
    });

    test('returns a new instance with same values when no args provided', () {
      final task = RegularTask(
        id: 'test-2',
        title: 'No changes',
        priority: Priority.medium,
        createdAt: DateTime(2026, 1, 1),
      );

      final copied = task.copyWith();

      expect(copied, isNot(same(task)));
      expect(copied.id, task.id);
      expect(copied.title, task.title);
      expect(copied.priority, task.priority);
      expect(copied.isDone, task.isDone);
    });

    test('UrgentTask copyWith preserves urgencyLevel', () {
      final task = UrgentTask(
        id: 'test-3',
        title: 'Urgent',
        priority: Priority.high,
        urgencyLevel: 4,
        createdAt: DateTime(2026, 1, 1),
      );

      final copied = task.copyWith(isDone: true);

      expect(copied, isA<UrgentTask>());
      expect(copied.urgencyLevel, 4);
      expect(copied.isDone, true);
    });
  });

  group('InMemoryTaskRepository', () {
    late InMemoryTaskRepository repository;

    setUp(() {
      repository = InMemoryTaskRepository();
    });

    test('add() then getAll() returns the added task', () async {
      final task = RegularTask(
        id: 'mem-1',
        title: 'Memory task',
        priority: Priority.high,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);
      final all = await repository.getAll();

      expect(all.length, 1);
      expect(all.first.id, 'mem-1');
      expect(all.first.title, 'Memory task');
    });

    test('update() replaces the existing task with the same id', () async {
      final task = RegularTask(
        id: 'mem-2',
        title: 'Original',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);

      final updated = task.copyWith(title: 'Updated title', isDone: true);
      await repository.update(updated);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'Updated title');
      expect(all.first.isDone, true);
    });

    test('delete() removes the task', () async {
      final task = RegularTask(
        id: 'mem-3',
        title: 'To delete',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);
      expect((await repository.getAll()).length, 1);

      await repository.delete('mem-3');
      expect((await repository.getAll()).length, 0);
    });

    test('delete() throws TaskNotFoundException for non-existent id', () async {
      expect(
        () => repository.delete('non-existent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('update() throws TaskNotFoundException for non-existent id', () async {
      final task = RegularTask(
        id: 'mem-4',
        title: 'No update',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => repository.update(task),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('getById() returns the task with matching id', () async {
      final task = RegularTask(
        id: 'mem-5',
        title: 'Find me',
        priority: Priority.high,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);
      final found = await repository.getById('mem-5');

      expect(found, isNotNull);
      expect(found!.title, 'Find me');
    });

    test('getById() returns null for non-existent id', () async {
      final found = await repository.getById('non-existent');
      expect(found, isNull);
    });

    test('getCount() returns the correct count', () async {
      expect(await repository.getCount(), 0);

      await repository.add(RegularTask(
        id: 'mem-6',
        title: 'Task 1',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      ));
      await repository.add(RegularTask(
        id: 'mem-7',
        title: 'Task 2',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      ));

      expect(await repository.getCount(), 2);
    });
  });

  group('JsonFileTaskRepository persistence', () {
    late String testFilePath;

    tearDown(() async {
      final file = File(testFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('add() then a new repository on the same file retrieves the task', () async {
      testFilePath = 'test_persist_${DateTime.now().millisecondsSinceEpoch}.json';

      final repository = JsonTaskRepository(testFilePath);
      final task = RegularTask(
        id: 'persist-1',
        title: 'Persisted task',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);

      // Create a new repository instance pointing to the same file
      final repository2 = JsonTaskRepository(testFilePath);
      final loaded = await repository2.getById('persist-1');

      expect(loaded, isNotNull);
      expect(loaded!.title, 'Persisted task');
      expect(loaded.priority, Priority.high);
      expect(loaded.deadline, DateTime(2026, 8, 31));
    });

    test('UrgentTask persists and loads correctly with urgencyLevel', () async {
      testFilePath = 'test_urgent_${DateTime.now().millisecondsSinceEpoch}.json';

      final repository = JsonTaskRepository(testFilePath);
      final task = UrgentTask(
        id: 'persist-urgent',
        title: 'Urgent persisted',
        priority: Priority.high,
        urgencyLevel: 5,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);

      final repository2 = JsonTaskRepository(testFilePath);
      final loaded = await repository2.getById('persist-urgent');

      expect(loaded, isNotNull);
      expect(loaded, isA<UrgentTask>());
      expect((loaded as UrgentTask).urgencyLevel, 5);
    });

    test('update() persists changes to file', () async {
      testFilePath = 'test_update_${DateTime.now().millisecondsSinceEpoch}.json';

      final repository = JsonTaskRepository(testFilePath);
      final task = RegularTask(
        id: 'persist-update',
        title: 'Original',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);

      final updated = task.copyWith(title: 'Updated', isDone: true);
      await repository.update(updated);

      final repository2 = JsonTaskRepository(testFilePath);
      final loaded = await repository2.getById('persist-update');

      expect(loaded, isNotNull);
      expect(loaded!.title, 'Updated');
      expect(loaded.isDone, true);
    });

    test('delete() removes task from file', () async {
      testFilePath = 'test_delete_${DateTime.now().millisecondsSinceEpoch}.json';

      final repository = JsonTaskRepository(testFilePath);
      final task = RegularTask(
        id: 'persist-delete',
        title: 'To delete',
        priority: Priority.low,
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.add(task);
      await repository.delete('persist-delete');

      final repository2 = JsonTaskRepository(testFilePath);
      final loaded = await repository2.getById('persist-delete');

      expect(loaded, isNull);
    });
  });

  group('Use cases with InMemoryTaskRepository', () {
    late InMemoryTaskRepository repository;

    setUp(() {
      repository = InMemoryTaskRepository();
    });

    group('AddTask', () {
      test('creates and adds a task successfully', () async {
        final useCase = AddTask(repository);
        final task = await useCase(
          title: 'New task',
          priority: Priority.high,
        );

        expect(task.title, 'New task');
        expect(task.priority, Priority.high);
        expect(task.isDone, false);

        final all = await repository.getAll();
        expect(all.length, 1);
        expect(all.first.id, task.id);
      });

      test('throws InvalidTaskTitleException for empty title', () async {
        final useCase = AddTask(repository);
        expect(
          () => useCase(title: '', priority: Priority.low),
          throwsA(isA<InvalidTaskTitleException>()),
        );
      });

      test('throws InvalidTaskTitleException for whitespace-only title', () async {
        final useCase = AddTask(repository);
        expect(
          () => useCase(title: '   ', priority: Priority.low),
          throwsA(isA<InvalidTaskTitleException>()),
        );
      });

      test('throws InvalidUrgencyLevelException for invalid urgency level', () async {
        final useCase = AddTask(repository);
        expect(
          () => useCase(
            title: 'Test',
            priority: Priority.high,
            isUrgent: true,
            urgencyLevel: 0,
          ),
          throwsA(isA<InvalidUrgencyLevelException>()),
        );
      });

      test('creates an UrgentTask when isUrgent is true', () async {
        final useCase = AddTask(repository);
        final task = await useCase(
          title: 'Urgent',
          priority: Priority.high,
          isUrgent: true,
          urgencyLevel: 4,
        );

        expect(task, isA<UrgentTask>());
        expect((task as UrgentTask).urgencyLevel, 4);
      });
    });

    group('ListTasks', () {
      test('returns all tasks sorted by priority', () async {
        final addTask = AddTask(repository);
        await addTask(title: 'Low', priority: Priority.low);
        await addTask(title: 'High', priority: Priority.high);
        await addTask(title: 'Medium', priority: Priority.medium);

        final useCase = ListTasks(repository);
        final tasks = await useCase();

        expect(tasks.length, 3);
        expect(tasks[0].title, 'High');
        expect(tasks[1].title, 'Medium');
        expect(tasks[2].title, 'Low');
      });

      test('filters done tasks when doneOnly is true', () async {
        final addTask = AddTask(repository);
        final task1 = await addTask(title: 'Done', priority: Priority.low);
        await addTask(title: 'Pending', priority: Priority.low);

        await repository.update(task1.copyWith(isDone: true));

        final useCase = ListTasks(repository);
        final doneTasks = await useCase(doneOnly: true);
        expect(doneTasks.length, 1);
        expect(doneTasks[0].title, 'Done');
      });

      test('filters pending tasks when pendingOnly is true', () async {
        final addTask = AddTask(repository);
        final task1 = await addTask(title: 'Done', priority: Priority.low);
        await addTask(title: 'Pending', priority: Priority.low);

        await repository.update(task1.copyWith(isDone: true));

        final useCase = ListTasks(repository);
        final pendingTasks = await useCase(pendingOnly: true);
        expect(pendingTasks.length, 1);
        expect(pendingTasks[0].title, 'Pending');
      });

      test('sorts by creation date when sortByPriority is false', () async {
        final addTask = AddTask(repository);
        final task1 = await addTask(title: 'First', priority: Priority.low);
        await Future.delayed(const Duration(milliseconds: 10));
        final task2 = await addTask(title: 'Second', priority: Priority.low);

        final useCase = ListTasks(repository);
        final tasks = await useCase(sortByPriority: false);

        expect(tasks[0].id, task1.id);
        expect(tasks[1].id, task2.id);
      });
    });

    group('ToggleTaskDone', () {
      test('toggles isDone from false to true', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Toggle me', priority: Priority.low);

        expect(task.isDone, false);

        final useCase = ToggleTaskDone(repository);
        await useCase(task.id);

        final updated = await repository.getById(task.id);
        expect(updated!.isDone, true);
      });

      test('toggles isDone from true to false', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Toggle me', priority: Priority.low);

        await repository.update(task.copyWith(isDone: true));

        final useCase = ToggleTaskDone(repository);
        await useCase(task.id);

        final updated = await repository.getById(task.id);
        expect(updated!.isDone, false);
      });

      test('throws TaskNotFoundException for non-existent id', () async {
        final useCase = ToggleTaskDone(repository);
        expect(
          () => useCase('non-existent'),
          throwsA(isA<TaskNotFoundException>()),
        );
      });
    });

    group('DeleteTask', () {
      test('deletes an existing task', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Delete me', priority: Priority.low);

        expect((await repository.getAll()).length, 1);

        final useCase = DeleteTask(repository);
        await useCase(task.id);

        expect((await repository.getAll()).length, 0);
      });

      test('throws TaskNotFoundException for non-existent id', () async {
        final useCase = DeleteTask(repository);
        expect(
          () => useCase('non-existent'),
          throwsA(isA<TaskNotFoundException>()),
        );
      });
    });

    group('UpdateTaskTitle', () {
      test('updates the title of an existing task', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Old title', priority: Priority.low);

        final useCase = UpdateTaskTitle(repository);
        await useCase(task.id, 'New title');

        final updated = await repository.getById(task.id);
        expect(updated!.title, 'New title');
      });

      test('throws TaskNotFoundException for non-existent id', () async {
        final useCase = UpdateTaskTitle(repository);
        expect(
          () => useCase('non-existent', 'New title'),
          throwsA(isA<TaskNotFoundException>()),
        );
      });

      test('throws InvalidTaskTitleException for empty title', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Original', priority: Priority.low);

        final useCase = UpdateTaskTitle(repository);
        expect(
          () => useCase(task.id, ''),
          throwsA(isA<InvalidTaskTitleException>()),
        );
      });

      test('throws InvalidTaskTitleException for whitespace-only title', () async {
        final addTask = AddTask(repository);
        final task = await addTask(title: 'Original', priority: Priority.low);

        final useCase = UpdateTaskTitle(repository);
        expect(
          () => useCase(task.id, '   '),
          throwsA(isA<InvalidTaskTitleException>()),
        );
      });
    });
  });

  group('TaskException hierarchy', () {
    test('TaskNotFoundException is a TaskException', () {
      const exception = TaskNotFoundException('test-id');
      expect(exception, isA<TaskException>());
      expect(exception.taskId, 'test-id');
    });

    test('InvalidTaskTitleException is a TaskException', () {
      final exception = InvalidTaskTitleException();
      expect(exception, isA<TaskException>());
    });

    test('InvalidPriorityException is a TaskException', () {
      const exception = InvalidPriorityException('invalid');
      expect(exception, isA<TaskException>());
    });

    test('InvalidUrgencyLevelException is a TaskException', () {
      const exception = InvalidUrgencyLevelException(99);
      expect(exception, isA<TaskException>());
    });

    test('PersistenceException is a TaskException', () {
      final exception = PersistenceException('Failed');
      expect(exception, isA<TaskException>());
    });

    test('RepositoryException is a TaskException', () {
      final exception = RepositoryException('Failed');
      expect(exception, isA<TaskException>());
    });
  });

  group('Repository<T> generic interface', () {
    test('TaskRepository extends Repository<Task>', () {
      final repository = InMemoryTaskRepository();
      expect(repository, isA<Repository<Task>>());
      expect(repository, isA<TaskRepository>());
    });

    test('JsonTaskRepository extends Repository<Task>', () async {
      final testFilePath = 'test_generic_${DateTime.now().millisecondsSinceEpoch}.json';
      final repository = JsonTaskRepository(testFilePath);

      expect(repository, isA<Repository<Task>>());
      expect(repository, isA<TaskRepository>());

      // Cleanup
      final file = File(testFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
