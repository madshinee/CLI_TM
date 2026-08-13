import 'dart:convert';
import 'dart:io';
import 'package:cli_task_manager/src/exceptions.dart';
import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';
import 'package:path/path.dart' as p;

class JsonTaskRepository implements TaskRepository {
  final String filePath;
  final Map<String, Task> _tasks = {};

  JsonTaskRepository(this.filePath) {
    _loadFromFile();
  }

  void _loadFromFile() {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _tasks.clear();
        return;
      }

      final content = file.readAsStringSync();
      if (content.isEmpty) {
        _tasks.clear();
        return;
      }

      final List<dynamic> jsonList = json.decode(content);
      _tasks.clear();
      
      for (final item in jsonList) {
        final task = _fromJson(item as Map<String, dynamic>);
        _tasks[task.id] = task;
      }
    } on FormatException catch (e) {
      throw PersistenceException('Failed to parse JSON file', e);
    } on IOException catch (e) {
      throw PersistenceException('Failed to read file', e);
    } catch (e) {
      throw PersistenceException('Unexpected error loading tasks', e);
    }
  }

  void _saveToFile() {
    try {
      final file = File(filePath);
      final dir = p.dirname(filePath);
      
      if (!Directory(dir).existsSync()) {
        Directory(dir).createSync(recursive: true);
      }

      final jsonList = _tasks.values.map((task) => task.toJson()).toList();
      final content = const JsonEncoder.withIndent('  ').convert(jsonList);
      file.writeAsStringSync(content);
    } on IOException catch (e) {
      throw PersistenceException('Failed to write to file', e);
    } catch (e) {
      throw PersistenceException('Unexpected error saving tasks', e);
    }
  }

  Task _fromJson(Map<String, dynamic> json) {
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
      )..isDone = isDone;
    } else {
      return RegularTask(
        id: id,
        title: title,
        priority: priority,
        deadline: deadline,
        createdAt: createdAt,
      )..isDone = isDone;
    }
  }

  @override
  Future<void> add(Task task) async {
    _tasks[task.id] = task;
    _saveToFile();
  }

  @override
  Future<void> delete(String id) async {
    if (!_tasks.containsKey(id)) {
      throw TaskNotFoundException(id);
    }
    _tasks.remove(id);
    _saveToFile();
  }

  @override
  Future<Task?> getById(String id) async {
    return _tasks[id];
  }

  @override
  Future<List<Task>> getAll() async {
    return _tasks.values.toList();
  }

  @override
  Future<void> update(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw TaskNotFoundException(task.id);
    }
    _tasks[task.id] = task;
    _saveToFile();
  }

  @override
  Future<int> getCount() async {
    return _tasks.length;
  }
}
