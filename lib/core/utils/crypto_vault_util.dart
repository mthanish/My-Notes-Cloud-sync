import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptedPayload {
  final String ciphertext;
  final String iv;
  final String salt;

  EncryptedPayload({
    required this.ciphertext,
    required this.iv,
    required this.salt,
  });
}

class CryptoVaultUtil {
  CryptoVaultUtil._();

  /// Derives a 32-byte key from PIN/password and salt using iterated SHA-256 (PBKDF2-like)
  static Uint8List deriveKey(String pin, Uint8List salt, {int iterations = 10000}) {
    List<int> current = utf8.encode(pin) + salt;
    for (int i = 0; i < iterations; i++) {
      current = sha256.convert(current).bytes;
    }
    return Uint8List.fromList(current);
  }

  /// Generates cryptographically secure random bytes
  static Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// Encrypts plaintext string using AES-256-CBC with PKCS7 padding
  static EncryptedPayload encryptString(String plaintext, String pin) {
    final salt = generateRandomBytes(16);
    final keyBytes = deriveKey(pin, salt);
    final ivBytes = generateRandomBytes(16);

    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return EncryptedPayload(
      ciphertext: encrypted.base64,
      iv: base64Encode(ivBytes),
      salt: base64Encode(salt),
    );
  }

  /// Decrypts ciphertext string using AES-256-CBC
  static String? decryptString({
    required String ciphertextBase64,
    required String ivBase64,
    required String saltBase64,
    required String pin,
  }) {
    try {
      final salt = base64Decode(saltBase64);
      final ivBytes = base64Decode(ivBase64);
      final keyBytes = deriveKey(pin, salt);

      final key = enc.Key(keyBytes);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = enc.Encrypted.fromBase64(ciphertextBase64);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Wrong PIN or corrupted payload
      return null;
    }
  }

  /// Hashes the master PIN for local verification
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }
}
