import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/mi_icons.dart';
import 'widgets/vault_pin_dialog.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final Map<String, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vaultRepo = ref.read(vaultRepositoryProvider);
      if (!vaultRepo.isUnlocked) {
        _promptUnlock();
      }
    });
  }

  void _promptUnlock() {
    final vaultRepo = ref.read(vaultRepositoryProvider);
    final hasPin = vaultRepo.hasPinSet();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VaultPinDialog(
        isSettingUp: !hasPin,
        onPinSubmitted: (pin) {
          if (!hasPin) {
            vaultRepo.setupPin(pin);
            ref.read(isVaultUnlockedProvider.notifier).set(true);
          } else {
            final success = vaultRepo.unlockVault(pin);
            if (success) {
              ref.read(isVaultUnlockedProvider.notifier).set(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incorrect Vault PIN')),
              );
              _promptUnlock();
            }
          }
        },
      ),
    );
  }

  void _showAddPasswordDialog() {
    final titleController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Add Password Note', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Bank, Email, Work)',
                  labelStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: userController,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  labelStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  labelText: 'Password (Encrypted with AES-256)',
                  labelStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  labelText: 'Optional Notes',
                  labelStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              final username = userController.text.trim();
              final pass = passController.text.trim();
              if (title.isNotEmpty && pass.isNotEmpty) {
                ref.read(vaultRepositoryProvider).saveVaultItem(
                      id: const Uuid().v4(),
                      title: title,
                      accountName: username,
                      rawPassword: pass,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Encrypted', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(isVaultUnlockedProvider);
    final vaultRepo = ref.watch(vaultRepositoryProvider);
    final vaultAsync = ref.watch(vaultStreamProvider);
    final items = vaultAsync.value ?? vaultRepo.getItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Password Vault', style: AppTypography.screenTitle),
        actions: [
          if (isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_rounded, color: AppColors.accent),
              tooltip: 'Lock Vault',
              onPressed: () {
                vaultRepo.lockVault();
                ref.read(isVaultUnlockedProvider.notifier).set(false);
                _visiblePasswords.clear();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !isUnlocked
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiIcons.vaultKey(size: 48, color: AppColors.accent),
                  const SizedBox(height: 16),
                  const Text('Vault is Locked', style: AppTypography.cardTitle),
                  const SizedBox(height: 8),
                  const Text(
                    'Protected with hardware-grade AES-256 encryption',
                    style: AppTypography.cardBody,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _promptUnlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Enter PIN to Unlock'),
                  ),
                ],
              ),
            )
          : items.isEmpty
              ? const Center(
                  child: Text('No password items in vault', style: AppTypography.emptyStateText),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isVisible = _visiblePasswords[item.id] ?? false;
                    final decrypted = isVisible ? vaultRepo.decryptPassword(item) : '••••••••';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MiIcons.vaultKey(size: 16, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.title, style: AppTypography.cardTitle),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => vaultRepo.deleteVaultItem(item.id),
                              ),
                            ],
                          ),
                          if (item.accountName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(item.accountName, style: AppTypography.cardBody),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    decrypted ?? 'Error decrypting',
                                    style: TextStyle(
                                      color: isVisible ? AppColors.accentLight : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: isVisible ? 0.5 : 3.0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20,
                                    color: AppColors.iconSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _visiblePasswords[item.id] = !isVisible;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.iconSecondary),
                                  onPressed: () {
                                    final plain = vaultRepo.decryptPassword(item);
                                    if (plain != null) {
                                      Clipboard.setData(ClipboardData(text: plain));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Password copied to clipboard')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(item.notes!, style: AppTypography.cardDate),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: isUnlocked
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: _showAddPasswordDialog,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
    );
  }
}
