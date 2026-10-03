import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mi_icons.dart';
import '../../../../services/sync_service.dart';

class TopHeaderBar extends ConsumerWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback? onSearchTap;

  const TopHeaderBar({
    super.key,
    required this.onSettingsTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? SyncStatus.synced;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: Subtle sync status indicator
            GestureDetector(
              onTap: () {
                final auth = ref.read(authServiceProvider);
                ref.read(syncServiceProvider).syncPendingWrites(auth.currentUid);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: syncStatus == SyncStatus.synced
                          ? AppColors.syncSuccess
                          : syncStatus == SyncStatus.syncing
                              ? AppColors.syncPending
                              : AppColors.syncOffline,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Center Tab Switcher: Notes tab & Tasks tab
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).set(0);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: MiIcons.notesTab(isSelected: activeTab == 0, size: 26),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).set(1);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: MiIcons.tasksTab(isSelected: activeTab == 1, size: 26),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Right: Settings Hexagon Icon & Optional Search Icon
            if (onSearchTap != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSearchTap,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search_rounded, color: AppColors.iconSecondary, size: 22),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSettingsTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: MiIcons.settingsHexagon(size: 23, color: AppColors.iconSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
