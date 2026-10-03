import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/mi_icons.dart';
import '../../../services/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final user = auth.currentSession;
    final syncService = ref.watch(syncServiceProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? syncService.currentStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: AppTypography.screenTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Account Section Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    (user?.displayName ?? 'MI').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.isAnonymous == true
                            ? (user?.displayName ?? 'Guest User')
                            : (user?.displayName ?? 'MI Notes User'),
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.isAnonymous == true
                            ? 'Offline Mode (Local Storage)'
                            : (user?.email ?? 'Google Account'),
                        style: AppTypography.cardDate,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user?.isAnonymous == true
                                  ? AppColors.syncOffline
                                  : (syncStatus == SyncStatus.synced
                                      ? AppColors.syncSuccess
                                      : AppColors.syncPending),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.isAnonymous == true
                                ? 'Local Storage Only'
                                : (syncStatus == SyncStatus.synced
                                    ? 'Cloud Synced'
                                    : syncStatus == SyncStatus.syncing
                                        ? 'Syncing changes...'
                                        : 'Offline / Sync Error'),
                            style: TextStyle(
                              fontSize: 11,
                              color: user?.isAnonymous == true
                                  ? AppColors.textTertiary
                                  : (syncStatus == SyncStatus.synced
                                      ? AppColors.syncSuccess
                                      : syncStatus == SyncStatus.syncing
                                          ? AppColors.syncPending
                                          : Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                      if (syncService.lastSyncError != null && user?.isAnonymous != true) ...[
                        const SizedBox(height: 4),
                        Text(
                          syncService.lastSyncError!,
                          style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('SYNCHRONIZATION & STORAGE'),
          _buildSettingsGroup([
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppColors.accent),
              title: const Text('Cloud Sync', style: AppTypography.taskTitle),
              subtitle: Text(
                user?.isAnonymous == true
                    ? 'Offline mode (Firebase setup required for sync)'
                    : 'Real-time listener with Cloud Firestore',
                style: AppTypography.cardDate,
              ),
              trailing: TextButton(
                onPressed: () async {
                  if (user?.isAnonymous == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connect Google account to enable Cloud Sync')),
                    );
                  } else {
                    try {
                      final count = await ref.read(syncServiceProvider).syncPendingWrites(auth.currentUid);
                      ref.read(notesRepositoryProvider).refresh();
                      ref.read(tasksRepositoryProvider).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade800,
                            content: Text(count > 0
                                ? 'Cloud sync complete ($count items updated)'
                                : 'Everything is already up-to-date with cloud'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade900,
                            duration: const Duration(seconds: 5),
                            content: Text('Sync error: $e'),
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Sync Now', style: TextStyle(color: AppColors.accent)),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1, indent: 56),
            const ListTile(
              leading: Icon(Icons.cloud_done_outlined, color: AppColors.iconSecondary),
              title: Text('Offline Persistence', style: AppTypography.taskTitle),
              subtitle: Text('Local Hive storage enabled (Offline-first)', style: AppTypography.cardDate),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.syncSuccess, size: 20),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('DATA MANAGEMENT'),
          _buildSettingsGroup([
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              title: const Text('Clear All Notes & Tasks', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              subtitle: const Text('Reset to a completely clean slate', style: AppTypography.cardDate),
              onTap: () {
                _showClearDataConfirmation(context, ref);
              },
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('SECURITY & VAULT'),
          _buildSettingsGroup([
            ListTile(
              leading: MiIcons.vaultKey(size: 20, color: AppColors.accent),
              title: const Text('Password Vault', style: AppTypography.taskTitle),
              subtitle: const Text('AES-256 hardware encryption', style: AppTypography.cardDate),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.iconSecondary),
              onTap: () => context.push('/vault'),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('APPEARANCE & ABOUT'),
          _buildSettingsGroup([
            const ListTile(
              leading: Icon(Icons.dark_mode_rounded, color: AppColors.iconSecondary),
              title: Text('Theme', style: AppTypography.taskTitle),
              subtitle: Text('Pitch Black & MI Warm Amber Accent', style: AppTypography.cardDate),
              trailing: Text('Dark', style: TextStyle(color: AppColors.accent)),
            ),
            const Divider(color: AppColors.divider, height: 1, indent: 56),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: AppColors.iconSecondary),
              title: Text('About My Notes', style: AppTypography.taskTitle),
              subtitle: Text('Version 1.0.0 • Clean Slate Build', style: AppTypography.cardDate),
            ),
          ]),

          const SizedBox(height: 24),
          // Sign Out Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                user?.isAnonymous == true ? 'Leave Guest Mode' : 'Sign Out',
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                await auth.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  void _showClearDataConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear All Notes & Tasks?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently delete all local notes, tasks, and vault items from your device. You will start with a completely fresh, empty app.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(localStorageProvider).clearAllData();
              // Trigger reload in repositories
              ref.invalidate(notesStreamProvider);
              ref.invalidate(tasksStreamProvider);
              ref.invalidate(vaultStreamProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared. Your notes app is now clean!')),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
