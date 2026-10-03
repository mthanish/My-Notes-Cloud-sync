import 'dart:async';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class TasksRepository {
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final String Function() _getCurrentUserId;

  final _tasksStreamController = StreamController<List<TaskModel>>.broadcast();
  StreamSubscription? _syncSub;

  TasksRepository({
    required LocalStorageService localStorage,
    required SyncService syncService,
    required String Function() getCurrentUserId,
  })  : _localStorage = localStorage,
        _syncService = syncService,
        _getCurrentUserId = getCurrentUserId {
    _refreshLocalTasks();
    _syncSub = _syncService.onTasksChanged.listen((_) {
      _refreshLocalTasks();
    });
  }

  void refresh() {
    _refreshLocalTasks();
  }

  Stream<List<TaskModel>> get tasksStream => _tasksStreamController.stream;

  void _refreshLocalTasks() {
    final uid = _getCurrentUserId();
    final allTasks = _localStorage.getAllTasks(userId: uid);
    final activeTasks = allTasks.where((t) => !t.isDeleted).toList()
      ..sort((a, b) {
        // Pending tasks first, then completed tasks
        if (!a.isCompleted && b.isCompleted) return -1;
        if (a.isCompleted && !b.isCompleted) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    _tasksStreamController.add(activeTasks);
  }

  List<TaskModel> getTasks() {
    final uid = _getCurrentUserId();
    final allTasks = _localStorage.getAllTasks(userId: uid);
    return allTasks.where((t) => !t.isDeleted).toList()
      ..sort((a, b) {
        if (!a.isCompleted && b.isCompleted) return -1;
        if (a.isCompleted && !b.isCompleted) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<void> saveTask(TaskModel task) async {
    final uid = _getCurrentUserId();
    final updatedTask = task.copyWith(
      userId: uid,
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );

    await _localStorage.saveTask(updatedTask);
    _refreshLocalTasks();

    unawaited(_syncService.syncTask(uid, updatedTask).then((_) {
      _refreshLocalTasks();
    }));
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final all = _localStorage.getAllTasks(userId: _getCurrentUserId());
    final matches = all.where((t) => t.id == taskId);
    if (matches.isNotEmpty) {
      final task = matches.first;
      await saveTask(task.copyWith(isCompleted: !task.isCompleted));
    }
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _getCurrentUserId();
    final all = _localStorage.getAllTasks(userId: uid);
    final matches = all.where((t) => t.id == taskId);
    if (matches.isNotEmpty) {
      final deleted = matches.first.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        isPendingSync: true,
      );
      await _localStorage.saveTask(deleted);
      _refreshLocalTasks();

      unawaited(_syncService.syncTask(uid, deleted).then((_) {
        _refreshLocalTasks();
      }));
    }
  }

  void notifyExternalUpdate() {
    _refreshLocalTasks();
  }

  void dispose() {
    _syncSub?.cancel();
    _tasksStreamController.close();
  }
}
