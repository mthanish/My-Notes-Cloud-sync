import 'package:cloud_firestore/cloud_firestore.dart';

class VaultItemModel {
  final String id;
  final String userId;
  final String title;
  final String accountName;
  final String encryptedPassword; // Base64 AES ciphertext
  final String iv; // Base64 Initialization Vector
  final String salt; // Base64 Salt for key derivation
  final String? notes;
  final DateTime updatedAt;
  final bool isDeleted;

  const VaultItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.accountName,
    required this.encryptedPassword,
    required this.iv,
    required this.salt,
    this.notes,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'accountName': accountName,
      'encryptedPassword': encryptedPassword,
      'iv': iv,
      'salt': salt,
      'notes': notes,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'accountName': accountName,
      'encryptedPassword': encryptedPassword,
      'iv': iv,
      'salt': salt,
      'notes': notes,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  factory VaultItemModel.fromMap(Map<String, dynamic> map, {String? idOverride}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return VaultItemModel(
      id: idOverride ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      accountName: map['accountName'] ?? '',
      encryptedPassword: map['encryptedPassword'] ?? '',
      iv: map['iv'] ?? '',
      salt: map['salt'] ?? '',
      notes: map['notes'],
      updatedAt: parseDate(map['updatedAt']),
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
