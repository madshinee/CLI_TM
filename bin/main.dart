import 'package:cli_task_manager/cli_task_manager.dart';

void main(List<String> args) async {
  final storagePath = 'tasks.json';
  final repository = JsonTaskRepository(storagePath);
  final service = TaskManagerService(repository);
  final cli = TaskCli(service, storagePath: storagePath);

  await cli.run(args);
}
