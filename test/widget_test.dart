import 'package:flutter_test/flutter_test.dart';
import 'package:notes_mi_clone/core/theme/app_colors.dart';
import 'package:notes_mi_clone/models/note_model.dart';
import 'package:notes_mi_clone/core/utils/date_formatter.dart';
import 'package:notes_mi_clone/core/utils/crypto_vault_util.dart';

void main() {
  group('MI Notes Unit & Model Tests', () {
    test('AppColors matches MI Notes palette', () {
      expect(AppColors.background.toARGB32(), 0xFF000000);
      expect(AppColors.accent.toARGB32(), 0xFFF5A623);
      expect(AppColors.cardBackground.toARGB32(), 0xFF202020);
    });

    test('NoteModel creation and serialization', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'test-1',
        userId: 'user-1',
        title: 'Quotes',
        content: 'Test quote content',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
      );

      final map = note.toMap();
      final revived = NoteModel.fromMap(map);

      expect(revived.id, 'test-1');
      expect(revived.title, 'Quotes');
      expect(revived.isPinned, true);
    });

    test('DateFormatter formats dates as in screenshots', () {
      final sept11 = DateTime(DateTime.now().year, 9, 11);
      final formatted = DateFormatter.formatCardDate(sept11);
      expect(formatted, 'September 11');

      final pastYear = DateTime(2025, 7, 21);
      final formattedPast = DateFormatter.formatCardDate(pastYear);
      expect(formattedPast.contains('2025'), true);
    });

    test('CryptoVaultUtil encrypts and decrypts with AES-256', () {
      const plaintext = 'SecretBankPassword@123';
      const pin = '1234';

      final encrypted = CryptoVaultUtil.encryptString(plaintext, pin);
      expect(encrypted.ciphertext.isNotEmpty, true);
      expect(encrypted.ciphertext != plaintext, true);

      final decrypted = CryptoVaultUtil.decryptString(
        ciphertextBase64: encrypted.ciphertext,
        ivBase64: encrypted.iv,
        saltBase64: encrypted.salt,
        pin: pin,
      );
      expect(decrypted, plaintext);

      final wrongDecrypt = CryptoVaultUtil.decryptString(
        ciphertextBase64: encrypted.ciphertext,
        ivBase64: encrypted.iv,
        saltBase64: encrypted.salt,
        pin: '9999',
      );
      expect(wrongDecrypt, isNull);
    });
  });
}
