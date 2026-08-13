import 'package:cli_task_manager/src/interfaces.dart';
import 'package:cli_task_manager/src/models/task.dart';

/// Use case for listing tasks with optional filtering and sorting.
///
/// When [sortByPriority] is `true` (the default), tasks are sorted by
/// priority (high → low) then by deadline (earliest first). When `false`,
/// tasks are sorted by creation date (oldest first).
///
/// [doneOnly] and [pendingOnly] are mutually exclusive filters.
class ListTasks {
  const ListTasks(this.repository);

  final TaskRepository repository;

  Future<List<Task>> call({
    bool sortByPriority = true,
    bool? doneOnly,
    bool? pendingOnly,
  }) async {
    final tasks = await repository.getAll();
    var list = tasks.toList();

    if (doneOnly == true) {
      list = list.where((t) => t.isDone).toList();
    } else if (pendingOnly == true) {
      list = list.where((t) => !t.isDone).toList();
    }

    if (sortByPriority) {
      list.sort();
    } else {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return list;
  }
}
