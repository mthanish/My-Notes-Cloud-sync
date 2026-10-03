import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads image bytes to Firebase Storage under users/{uid}/attachments/{uuid}.jpg
  /// Returns download URL or local data identifier.
  Future<String> uploadImageBytes({
    required String uid,
    required Uint8List bytes,
    String? customName,
  }) async {
    final fileName = customName ?? '${const Uuid().v4()}.jpg';
    if (!FirebaseService.isInitialized) {
      developer.log('StorageService: Firebase not initialized, generating local asset URL', name: 'StorageService');
      return 'local_asset://$fileName';
    }

    try {
      final ref = _storage.ref().child('users/$uid/attachments/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log('Storage upload error: $e', name: 'StorageService');
      return 'local_asset://$fileName';
    }
  }

  /// Deletes file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      developer.log('Storage delete error: $e', name: 'StorageService');
    }
  }
}
