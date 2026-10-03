import 'dart:async';
import '../models/note_model.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class NotesRepository {
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final String Function() _getCurrentUserId;

  final _notesStreamController = StreamController<List<NoteModel>>.broadcast();
  StreamSubscription? _syncSub;

  NotesRepository({
    required LocalStorageService localStorage,
    required SyncService syncService,
    required String Function() getCurrentUserId,
  })  : _localStorage = localStorage,
        _syncService = syncService,
        _getCurrentUserId = getCurrentUserId {
    _refreshLocalNotes();
    _syncSub = _syncService.onNotesChanged.listen((_) {
      _refreshLocalNotes();
    });
  }

  void refresh() {
    _refreshLocalNotes();
  }

  Stream<List<NoteModel>> get notesStream => _notesStreamController.stream;

  void _refreshLocalNotes() {
    final uid = _getCurrentUserId();
    final allNotes = _localStorage.getAllNotes(userId: uid);
    // Filter out deleted notes and sort pinned first, then by updatedAt descending
    final activeNotes = allNotes.where((n) => !n.isDeleted).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    _notesStreamController.add(activeNotes);
  }

  List<NoteModel> getNotes() {
    final uid = _getCurrentUserId();
    final allNotes = _localStorage.getAllNotes(userId: uid);
    return allNotes.where((n) => !n.isDeleted).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  NoteModel? getNoteById(String id) {
    return _localStorage.getNoteById(id);
  }

  /// Create or update note - local DB first, then background sync
  Future<void> saveNote(NoteModel note) async {
    final uid = _getCurrentUserId();
    final updatedNote = note.copyWith(
      userId: uid,
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );

    // 1. Immediate local write
    await _localStorage.saveNote(updatedNote);
    _refreshLocalNotes();

    // 2. Sync to Firestore
    unawaited(_syncService.syncNote(uid, updatedNote).then((_) {
      _refreshLocalNotes();
    }));
  }

  /// Toggle pin status
  Future<void> togglePin(String noteId) async {
    final note = _localStorage.getNoteById(noteId);
    if (note != null) {
      await saveNote(note.copyWith(isPinned: !note.isPinned));
    }
  }

  /// Soft delete note
  Future<void> deleteNote(String noteId) async {
    final uid = _getCurrentUserId();
    final note = _localStorage.getNoteById(noteId);
    if (note != null) {
      final deleted = note.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        isPendingSync: true,
      );
      // Soft delete locally
      await _localStorage.saveNote(deleted);
      _refreshLocalNotes();

      // Sync deletion
      unawaited(_syncService.syncNote(uid, deleted).then((_) {
        _refreshLocalNotes();
      }));
    }
  }

  /// Change category / folder
  Future<void> moveNoteCategory(String noteId, String newCategory) async {
    final note = _localStorage.getNoteById(noteId);
    if (note != null) {
      await saveNote(note.copyWith(category: newCategory));
    }
  }

  void notifyExternalUpdate() {
    _refreshLocalNotes();
  }

  void dispose() {
    _syncSub?.cancel();
    _notesStreamController.close();
  }
}
