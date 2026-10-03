import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/vault_item_model.dart';
import '../repositories/notes_repository.dart';
import '../repositories/tasks_repository.dart';
import '../repositories/vault_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

// ---------------------------------------------------------------------------
// SERVICES PROVIDERS
// ---------------------------------------------------------------------------

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final local = ref.watch(localStorageProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  final service = SyncService(localStorage: local, firestoreService: firestore);
  ref.onDispose(() => service.dispose());
  return service;
});

// Current User Session Stream Provider
final userSessionProvider = StreamProvider<UserSession?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.sessionStream;
});

// ---------------------------------------------------------------------------
// REPOSITORY PROVIDERS
// ---------------------------------------------------------------------------

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final local = ref.watch(localStorageProvider);
  final sync = ref.watch(syncServiceProvider);
  final auth = ref.watch(authServiceProvider);

  final repo = NotesRepository(
    localStorage: local,
    syncService: sync,
    getCurrentUserId: () => auth.currentUid,
  );

  // Initialize background sync for current user if already logged in
  if (auth.currentUid != 'guest_user') {
    sync.initializeSync(auth.currentUid);
  }

  // React to auth changes so sync starts automatically when user logs in or out
  final sessionSub = auth.sessionStream.listen((session) async {
    if (session != null && !session.isAnonymous) {
      await local.migrateGuestDataToUser(session.uid);
      sync.initializeSync(session.uid);
    }
    repo.refresh();
  });

  ref.onDispose(() {
    sessionSub.cancel();
    repo.dispose();
  });
  return repo;
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final local = ref.watch(localStorageProvider);
  final sync = ref.watch(syncServiceProvider);
  final auth = ref.watch(authServiceProvider);

  final repo = TasksRepository(
    localStorage: local,
    syncService: sync,
    getCurrentUserId: () => auth.currentUid,
  );

  final sessionSub = auth.sessionStream.listen((_) {
    repo.refresh();
  });

  ref.onDispose(() {
    sessionSub.cancel();
    repo.dispose();
  });
  return repo;
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final local = ref.watch(localStorageProvider);
  final sync = ref.watch(syncServiceProvider);
  final auth = ref.watch(authServiceProvider);

  final repo = VaultRepository(
    localStorage: local,
    syncService: sync,
    getCurrentUserId: () => auth.currentUid,
  );

  final sessionSub = auth.sessionStream.listen((_) {
    repo.refresh();
  });

  ref.onDispose(() {
    sessionSub.cancel();
    repo.dispose();
  });
  return repo;
});

// ---------------------------------------------------------------------------
// REACTIVE DATA STREAMS
// ---------------------------------------------------------------------------

final notesStreamProvider = StreamProvider<List<NoteModel>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.notesStream;
});

final tasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.tasksStream;
});

final vaultStreamProvider = StreamProvider<List<VaultItemModel>>((ref) {
  final repo = ref.watch(vaultRepositoryProvider);
  return repo.vaultStream;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return sync.syncStatusStream;
});

// ---------------------------------------------------------------------------
// UI STATE NOTIFIERS (Riverpod 3.x)
// ---------------------------------------------------------------------------

/// Active Tab: 0 = Notes, 1 = Tasks
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}
final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(ActiveTabNotifier.new);

/// Active Category Filter ('All', 'notes', 'passwords', 'Uncategorised')
class ActiveCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}
final activeCategoryProvider = NotifierProvider<ActiveCategoryNotifier, String>(ActiveCategoryNotifier.new);

/// Active Search Query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Vault Unlocked State
class VaultUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}
final isVaultUnlockedProvider = NotifierProvider<VaultUnlockedNotifier, bool>(VaultUnlockedNotifier.new);
