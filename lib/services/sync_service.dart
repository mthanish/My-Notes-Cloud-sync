import 'dart:async';
import 'dart:developer' as developer;
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/vault_item_model.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

enum SyncStatus {
  synced,
  syncing,
  offline,
}

class SyncService {
  final LocalStorageService _localStorage;
  final FirestoreService _firestoreService;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.synced;
  String? _lastSyncError;

  final _onNotesChangedController = StreamController<void>.broadcast();
  final _onTasksChangedController = StreamController<void>.broadcast();
  final _onVaultChangedController = StreamController<void>.broadcast();

  StreamSubscription<List<NoteModel>>? _remoteNotesSub;
  StreamSubscription<List<TaskModel>>? _remoteTasksSub;
  StreamSubscription<List<VaultItemModel>>? _remoteVaultSub;

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus get currentStatus => _currentStatus;
  String? get lastSyncError => _lastSyncError;

  Stream<void> get onNotesChanged => _onNotesChangedController.stream;
  Stream<void> get onTasksChanged => _onTasksChangedController.stream;
  Stream<void> get onVaultChanged => _onVaultChangedController.stream;

  SyncService({
    required LocalStorageService localStorage,
    required FirestoreService firestoreService,
  })  : _localStorage = localStorage,
        _firestoreService = firestoreService;

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Starts listening to Firestore realtime changes and triggers initial pending sync
  void initializeSync(String uid) {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      _setStatus(SyncStatus.offline);
      return;
    }

    _setStatus(SyncStatus.syncing);

    // Cancel existing subscriptions if any
    _remoteNotesSub?.cancel();
    _remoteTasksSub?.cancel();
    _remoteVaultSub?.cancel();

    // 1. Subscribe to Firestore Notes
    _remoteNotesSub = _firestoreService.streamNotes(uid).listen(
      (remoteNotes) async {
        await _mergeRemoteNotes(remoteNotes);
        _lastSyncError = null;
        _setStatus(SyncStatus.synced);
      },
      onError: (err) {
        developer.log('Remote notes listener error: $err', name: 'SyncService');
        _lastSyncError = err.toString();
        _setStatus(SyncStatus.offline);
      },
    );

    // 2. Subscribe to Firestore Tasks
    _remoteTasksSub = _firestoreService.streamTasks(uid).listen(
      (remoteTasks) async {
        await _mergeRemoteTasks(remoteTasks);
        _lastSyncError = null;
        _setStatus(SyncStatus.synced);
      },
      onError: (err) {
        developer.log('Remote tasks listener error: $err', name: 'SyncService');
        _lastSyncError = err.toString();
        _setStatus(SyncStatus.offline);
      },
    );

    // 3. Subscribe to Firestore Vault
    _remoteVaultSub = _firestoreService.streamVault(uid).listen(
      (remoteVaultItems) async {
        await _mergeRemoteVault(remoteVaultItems);
        _lastSyncError = null;
        _setStatus(SyncStatus.synced);
      },
      onError: (err) {
        developer.log('Remote vault listener error: $err', name: 'SyncService');
      },
    );

    // Flush any pending local changes to remote
    syncPendingWrites(uid);
  }

  /// Push all local pending changes up to Firestore
  Future<int> syncPendingWrites(String uid) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      _setStatus(SyncStatus.offline);
      _lastSyncError = 'Offline or guest user: connect Google account to sync.';
      return 0;
    }

    try {
      _setStatus(SyncStatus.syncing);
      int syncedCount = 0;

      // Pending Notes
      final pendingNotes = _localStorage.getPendingSyncNotes();
      for (final note in pendingNotes) {
        if (note.isDeleted) {
          await _firestoreService.softDeleteNote(uid, note.id);
        } else {
          await _firestoreService.writeNote(uid, note);
        }
        await _localStorage.saveNote(note.copyWith(isPendingSync: false));
        syncedCount++;
      }

      // Pending Tasks
      final pendingTasks = _localStorage.getPendingSyncTasks();
      for (final task in pendingTasks) {
        if (task.isDeleted) {
          await _firestoreService.softDeleteTask(uid, task.id);
        } else {
          await _firestoreService.writeTask(uid, task);
        }
        await _localStorage.saveTask(task.copyWith(isPendingSync: false));
        syncedCount++;
      }

      _lastSyncError = null;
      _setStatus(SyncStatus.synced);
      if (syncedCount > 0) {
        _onNotesChangedController.add(null);
        _onTasksChangedController.add(null);
      }
      return syncedCount;
    } catch (e) {
      developer.log('syncPendingWrites error: $e', name: 'SyncService');
      _lastSyncError = e.toString();
      _setStatus(SyncStatus.offline);
      rethrow;
    }
  }

  /// Sync a single note change immediately
  Future<void> syncNote(String uid, NoteModel note) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      await _localStorage.saveNote(note.copyWith(isPendingSync: true));
      _setStatus(SyncStatus.offline);
      return;
    }

    try {
      _setStatus(SyncStatus.syncing);
      if (note.isDeleted) {
        await _firestoreService.softDeleteNote(uid, note.id);
      } else {
        await _firestoreService.writeNote(uid, note);
      }
      await _localStorage.saveNote(note.copyWith(isPendingSync: false));
      _lastSyncError = null;
      _setStatus(SyncStatus.synced);
    } catch (e) {
      developer.log('syncNote offline queue: $e', name: 'SyncService');
      _lastSyncError = e.toString();
      await _localStorage.saveNote(note.copyWith(isPendingSync: true));
      _setStatus(SyncStatus.offline);
      rethrow;
    }
  }

  /// Sync a single task change immediately
  Future<void> syncTask(String uid, TaskModel task) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      await _localStorage.saveTask(task.copyWith(isPendingSync: true));
      _setStatus(SyncStatus.offline);
      return;
    }

    try {
      _setStatus(SyncStatus.syncing);
      if (task.isDeleted) {
        await _firestoreService.softDeleteTask(uid, task.id);
      } else {
        await _firestoreService.writeTask(uid, task);
      }
      await _localStorage.saveTask(task.copyWith(isPendingSync: false));
      _lastSyncError = null;
      _setStatus(SyncStatus.synced);
    } catch (e) {
      developer.log('syncTask offline queue: $e', name: 'SyncService');
      _lastSyncError = e.toString();
      await _localStorage.saveTask(task.copyWith(isPendingSync: true));
      _setStatus(SyncStatus.offline);
      rethrow;
    }
  }

  /// Sync a vault item
  Future<void> syncVaultItem(String uid, VaultItemModel item) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      await _localStorage.saveVaultItem(item);
      return;
    }
    try {
      if (item.isDeleted) {
        await _firestoreService.softDeleteVaultItem(uid, item.id);
      } else {
        await _firestoreService.writeVaultItem(uid, item);
      }
      await _localStorage.saveVaultItem(item);
      _lastSyncError = null;
    } catch (e) {
      developer.log('syncVaultItem error: $e', name: 'SyncService');
      _lastSyncError = e.toString();
      await _localStorage.saveVaultItem(item);
    }
  }

  // ---------------------------------------------------------------------------
  // MERGE LOGIC (Latest updatedAt wins conflict resolution)
  // ---------------------------------------------------------------------------

  Future<void> _mergeRemoteNotes(List<NoteModel> remoteNotes) async {
    bool hasChanges = false;
    for (final remote in remoteNotes) {
      final local = _localStorage.getNoteById(remote.id);
      if (local == null) {
        // Remote is brand new note
        await _localStorage.saveNote(remote.copyWith(isPendingSync: false));
        hasChanges = true;
      } else if (!local.isPendingSync) {
        // Remote is newer or equal and local had no pending unsaved edit
        if (remote.updatedAt.isAfter(local.updatedAt) || remote.updatedAt.isAtSameMomentAs(local.updatedAt)) {
          await _localStorage.saveNote(remote.copyWith(isPendingSync: false));
          hasChanges = true;
        }
      } else {
        // Local has pending changes! Compare timestamps
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          // Remote update wins
          await _localStorage.saveNote(remote.copyWith(isPendingSync: false));
          hasChanges = true;
        }
      }
    }
    if (hasChanges || remoteNotes.isNotEmpty) {
      _onNotesChangedController.add(null);
    }
  }

  Future<void> _mergeRemoteTasks(List<TaskModel> remoteTasks) async {
    bool hasChanges = false;
    for (final remote in remoteTasks) {
      final local = _localStorage.getTaskById(remote.id);
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        await _localStorage.saveTask(remote.copyWith(isPendingSync: false));
        hasChanges = true;
      }
    }
    if (hasChanges || remoteTasks.isNotEmpty) {
      _onTasksChangedController.add(null);
    }
  }

  Future<void> _mergeRemoteVault(List<VaultItemModel> remoteItems) async {
    for (final remote in remoteItems) {
      await _localStorage.saveVaultItem(remote);
    }
    if (remoteItems.isNotEmpty) {
      _onVaultChangedController.add(null);
    }
  }

  void dispose() {
    _remoteNotesSub?.cancel();
    _remoteTasksSub?.cancel();
    _remoteVaultSub?.cancel();
    _syncStatusController.close();
    _onNotesChangedController.close();
    _onTasksChangedController.close();
    _onVaultChangedController.close();
  }
}
