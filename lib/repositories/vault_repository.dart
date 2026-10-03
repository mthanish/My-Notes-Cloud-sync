import 'dart:async';
import '../core/utils/crypto_vault_util.dart';
import '../models/vault_item_model.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class VaultRepository {
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final String Function() _getCurrentUserId;

  String? _unlockedPin;
  bool get isUnlocked => _unlockedPin != null;

  final _vaultStreamController = StreamController<List<VaultItemModel>>.broadcast();
  StreamSubscription? _syncSub;

  VaultRepository({
    required LocalStorageService localStorage,
    required SyncService syncService,
    required String Function() getCurrentUserId,
  })  : _localStorage = localStorage,
        _syncService = syncService,
        _getCurrentUserId = getCurrentUserId {
    _refreshVault();
    _syncSub = _syncService.onVaultChanged.listen((_) {
      _refreshVault();
    });
  }

  void refresh() {
    _refreshVault();
  }

  Stream<List<VaultItemModel>> get vaultStream => _vaultStreamController.stream;

  void _refreshVault() {
    final uid = _getCurrentUserId();
    final items = _localStorage.getAllVaultItems(userId: uid).where((v) => !v.isDeleted).toList();
    _vaultStreamController.add(items);
  }

  List<VaultItemModel> getItems() {
    final uid = _getCurrentUserId();
    return _localStorage.getAllVaultItems(userId: uid).where((v) => !v.isDeleted).toList();
  }

  bool hasPinSet() {
    return _localStorage.getVaultPinHash() != null;
  }

  /// Sets master PIN
  Future<void> setupPin(String pin) async {
    final saltBytes = CryptoVaultUtil.generateRandomBytes(16);
    final saltStr = String.fromCharCodes(saltBytes);
    final hash = CryptoVaultUtil.hashPin(pin, saltStr);

    await _localStorage.saveVaultPin(hash, saltStr);
    _unlockedPin = pin;
  }

  /// Verifies PIN to unlock
  bool unlockVault(String pin) {
    final savedHash = _localStorage.getVaultPinHash();
    final savedSalt = _localStorage.getVaultPinSalt();

    if (savedHash == null || savedSalt == null) {
      // First time, allow unlock
      _unlockedPin = pin;
      return true;
    }

    final testHash = CryptoVaultUtil.hashPin(pin, savedSalt);
    if (testHash == savedHash) {
      _unlockedPin = pin;
      return true;
    }
    return false;
  }

  void lockVault() {
    _unlockedPin = null;
  }

  /// Decrypts item password if vault is unlocked
  String? decryptPassword(VaultItemModel item) {
    if (_unlockedPin == null) return null;
    return CryptoVaultUtil.decryptString(
      ciphertextBase64: item.encryptedPassword,
      ivBase64: item.iv,
      saltBase64: item.salt,
      pin: _unlockedPin!,
    );
  }

  /// Save vault item
  Future<void> saveVaultItem({
    required String id,
    required String title,
    required String accountName,
    required String rawPassword,
    String? notes,
  }) async {
    final pin = _unlockedPin ?? '1234';
    final payload = CryptoVaultUtil.encryptString(rawPassword, pin);
    final uid = _getCurrentUserId();

    final item = VaultItemModel(
      id: id,
      userId: uid,
      title: title,
      accountName: accountName,
      encryptedPassword: payload.ciphertext,
      iv: payload.iv,
      salt: payload.salt,
      notes: notes,
      updatedAt: DateTime.now(),
    );

    await _localStorage.saveVaultItem(item);
    _refreshVault();

    unawaited(_syncService.syncVaultItem(uid, item));
  }

  /// Delete vault item
  Future<void> deleteVaultItem(String id) async {
    final uid = _getCurrentUserId();
    final all = _localStorage.getAllVaultItems(userId: uid);
    final matches = all.where((v) => v.id == id);
    if (matches.isNotEmpty) {
      final deleted = VaultItemModel(
        id: id,
        userId: uid,
        title: matches.first.title,
        accountName: matches.first.accountName,
        encryptedPassword: matches.first.encryptedPassword,
        iv: matches.first.iv,
        salt: matches.first.salt,
        notes: matches.first.notes,
        updatedAt: DateTime.now(),
        isDeleted: true,
      );
      await _localStorage.saveVaultItem(deleted);
      _refreshVault();
      unawaited(_syncService.syncVaultItem(uid, deleted));
    }
  }

  void dispose() {
    _syncSub?.cancel();
    _vaultStreamController.close();
  }
}
