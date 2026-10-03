import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/vault_item_model.dart';
import 'firebase_service.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('notes');
  }

  CollectionReference<Map<String, dynamic>> _tasksCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _vaultCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('vault');
  }

  Future<void> updateUserProfile(String uid, {String? email, String? displayName}) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email ?? '',
        'displayName': displayName ?? '',
        'lastActive': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Firestore updateUserProfile error: $e', name: 'FirestoreService');
    }
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME NOTES STREAM
  // ---------------------------------------------------------------------------

  Stream<List<NoteModel>> streamNotes(String uid) {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      return const Stream.empty();
    }
    return _notesCollection(uid).snapshots().map((snapshot) {
      final notes = snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    });
  }

  Future<void> writeNote(String uid, NoteModel note) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') return;
    try {
      await _notesCollection(uid).doc(note.id).set(
            note.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Firestore writeNote error: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  Future<void> softDeleteNote(String uid, String noteId) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') return;
    try {
      await _notesCollection(uid).doc(noteId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      developer.log('Firestore softDeleteNote error: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME TASKS STREAM
  // ---------------------------------------------------------------------------

  Stream<List<TaskModel>> streamTasks(String uid) {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      return const Stream.empty();
    }
    return _tasksCollection(uid).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  Future<void> writeTask(String uid, TaskModel task) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') return;
    try {
      await _tasksCollection(uid).doc(task.id).set(
            task.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Firestore writeTask error: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  Future<void> softDeleteTask(String uid, String taskId) async {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') return;
    try {
      await _tasksCollection(uid).doc(taskId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      developer.log('Firestore softDeleteTask error: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VAULT ITEMS
  // ---------------------------------------------------------------------------

  Stream<List<VaultItemModel>> streamVault(String uid) {
    if (!FirebaseService.isInitialized || uid.isEmpty || uid == 'guest_user') {
      return const Stream.empty();
    }
    return _vaultCollection(uid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => VaultItemModel.fromMap(doc.data(), idOverride: doc.id))
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Future<void> writeVaultItem(String uid, VaultItemModel item) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await _vaultCollection(uid).doc(item.id).set(
            item.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Firestore writeVaultItem error: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  Future<void> softDeleteVaultItem(String uid, String itemId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await _vaultCollection(uid).doc(itemId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      developer.log('Firestore softDeleteVaultItem error: $e', name: 'FirestoreService');
      rethrow;
    }
  }
}
