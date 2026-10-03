import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/vault_item_model.dart';

class LocalStorageService {
  static const String notesBoxName = 'mi_notes_box';
  static const String tasksBoxName = 'mi_tasks_box';
  static const String vaultBoxName = 'mi_vault_box';
  static const String settingsBoxName = 'mi_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(notesBoxName);
    await Hive.openBox(tasksBoxName);
    await Hive.openBox(vaultBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box get _notesBox => Hive.box(notesBoxName);
  Box get _tasksBox => Hive.box(tasksBoxName);
  Box get _vaultBox => Hive.box(vaultBoxName);
  Box get _settingsBox => Hive.box(settingsBoxName);

  // ---------------------------------------------------------------------------
  // NOTES
  // ---------------------------------------------------------------------------

  List<NoteModel> getAllNotes({required String userId}) {
    final list = <NoteModel>[];
    for (final key in _notesBox.keys) {
      final raw = _notesBox.get(key);
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          final note = NoteModel.fromMap(map);
          if (note.userId == userId || note.userId.isEmpty) {
            list.add(note);
          }
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note.toMap());
  }

  Future<void> saveNotes(List<NoteModel> notes) async {
    final map = {for (var n in notes) n.id: n.toMap()};
    await _notesBox.putAll(map);
  }

  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  NoteModel? getNoteById(String noteId) {
    final raw = _notesBox.get(noteId);
    if (raw == null) return null;
    return NoteModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  List<NoteModel> getPendingSyncNotes() {
    final list = <NoteModel>[];
    for (final key in _notesBox.keys) {
      final raw = _notesBox.get(key);
      if (raw != null) {
        final note = NoteModel.fromMap(Map<String, dynamic>.from(raw as Map));
        if (note.isPendingSync) {
          list.add(note);
        }
      }
    }
    return list;
  }

  /// Migrates notes and tasks created during guest/offline mode to the authenticated user ID
  Future<void> migrateGuestDataToUser(String targetUserId) async {
    if (targetUserId.isEmpty || targetUserId == 'guest_user') return;

    final notes = getAllNotes(userId: 'guest_user');
    for (final note in notes) {
      if (note.userId == 'guest_user' || note.userId.isEmpty) {
        await saveNote(note.copyWith(
          userId: targetUserId,
          isPendingSync: true,
        ));
      }
    }

    final tasks = getAllTasks(userId: 'guest_user');
    for (final task in tasks) {
      if (task.userId == 'guest_user' || task.userId.isEmpty) {
        await saveTask(task.copyWith(
          userId: targetUserId,
          isPendingSync: true,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TASKS
  // ---------------------------------------------------------------------------

  List<TaskModel> getAllTasks({required String userId}) {
    final list = <TaskModel>[];
    for (final key in _tasksBox.keys) {
      final raw = _tasksBox.get(key);
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          final task = TaskModel.fromMap(map);
          if (task.userId == userId || task.userId.isEmpty) {
            list.add(task);
          }
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveTask(TaskModel task) async {
    await _tasksBox.put(task.id, task.toMap());
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final map = {for (var t in tasks) t.id: t.toMap()};
    await _tasksBox.putAll(map);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
  }

  TaskModel? getTaskById(String taskId) {
    final raw = _tasksBox.get(taskId);
    if (raw == null) return null;
    return TaskModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  List<TaskModel> getPendingSyncTasks() {
    final list = <TaskModel>[];
    for (final key in _tasksBox.keys) {
      final raw = _tasksBox.get(key);
      if (raw != null) {
        final task = TaskModel.fromMap(Map<String, dynamic>.from(raw as Map));
        if (task.isPendingSync) {
          list.add(task);
        }
      }
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // VAULT
  // ---------------------------------------------------------------------------

  List<VaultItemModel> getAllVaultItems({required String userId}) {
    final list = <VaultItemModel>[];
    for (final key in _vaultBox.keys) {
      final raw = _vaultBox.get(key);
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          final item = VaultItemModel.fromMap(map);
          if (item.userId == userId || item.userId.isEmpty) {
            list.add(item);
          }
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveVaultItem(VaultItemModel item) async {
    await _vaultBox.put(item.id, item.toMap());
  }

  Future<void> deleteVaultItem(String id) async {
    await _vaultBox.delete(id);
  }

  // ---------------------------------------------------------------------------
  // SETTINGS & PIN
  // ---------------------------------------------------------------------------

  String? getVaultPinHash() {
    return _settingsBox.get('vault_pin_hash') as String?;
  }

  String? getVaultPinSalt() {
    return _settingsBox.get('vault_pin_salt') as String?;
  }

  Future<void> saveVaultPin(String hash, String salt) async {
    await _settingsBox.put('vault_pin_hash', hash);
    await _settingsBox.put('vault_pin_salt', salt);
  }

  bool getHasSeededData() {
    return _settingsBox.get('has_seeded_initial_data', defaultValue: false) as bool;
  }

  Future<void> setHasSeededData(bool value) async {
    await _settingsBox.put('has_seeded_initial_data', value);
  }

  /// Purges previously preloaded screenshot seed notes, tasks, and vault items
  Future<void> purgeDemoSeedData() async {
    const seedNoteTitles = {
      'Quotes',
      'Mein shayar to...',
      'Movies to watch',
      'winners',
      'Dropshipping...',
      'Mummy...',
      'Books',
      'SBI PW',
      'Ideas',
    };

    for (final key in _notesBox.keys.toList()) {
      final raw = _notesBox.get(key);
      if (raw != null && raw is Map) {
        final title = raw['title'] as String?;
        if (title != null && seedNoteTitles.contains(title)) {
          await _notesBox.delete(key);
        }
      }
    }

    const seedTaskTitles = {
      'Complete cross-device MI Notes build',
      'Verify offline SQLite / Hive cache persistence',
      'Test Firestore multi-device real-time sync',
    };

    for (final key in _tasksBox.keys.toList()) {
      final raw = _tasksBox.get(key);
      if (raw != null && raw is Map) {
        final title = raw['title'] as String?;
        if (title != null && seedTaskTitles.contains(title)) {
          await _tasksBox.delete(key);
        }
      }
    }

    const seedVaultTitles = {
      'SBI Net Banking',
      'Cloud Workstation',
    };

    for (final key in _vaultBox.keys.toList()) {
      final raw = _vaultBox.get(key);
      if (raw != null && raw is Map) {
        final title = raw['title'] as String?;
        if (title != null && seedVaultTitles.contains(title)) {
          await _vaultBox.delete(key);
        }
      }
    }
  }

  /// Clears all notes from local box
  Future<void> clearAllNotes() async {
    await _notesBox.clear();
  }

  /// Clears all notes, tasks, and vault items
  Future<void> clearAllData() async {
    await _notesBox.clear();
    await _tasksBox.clear();
    await _vaultBox.clear();
  }
}
