import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/mi_icons.dart';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  final List<String> _folders = [
    'Work & Projects',
    'Personal & Journal',
    'Finances',
    'Fitness & Health',
  ];

  void _showAddFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('New Folder', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _folders.add(name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Folders & Categories', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Built-in categories
          _buildCategoryTile('All Notes', Icons.all_inbox_rounded, 'All'),
          _buildCategoryTile('Notes', Icons.notes_rounded, 'notes'),
          _buildCategoryTile('Password Vault', Icons.lock_outline_rounded, 'passwords'),
          _buildCategoryTile('Uncategorised', Icons.label_off_outlined, 'Uncategorised'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Custom Folders', style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.textTertiary)),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.accent),
                onPressed: _showAddFolderDialog,
              ),
            ],
          ),

          ..._folders.map((folder) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: MiIcons.folder(size: 20, color: AppColors.accent),
                  title: Text(folder, style: AppTypography.taskTitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.iconSecondary),
                    onPressed: () {
                      setState(() => _folders.remove(folder));
                    },
                  ),
                  onTap: () {
                    ref.read(activeCategoryProvider.notifier).set(folder);
                    context.pop();
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String title, IconData icon, String categoryKey) {
    final active = ref.watch(activeCategoryProvider) == categoryKey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.chipBackgroundSelected : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? AppColors.accent : AppColors.iconSecondary, size: 22),
        title: Text(title, style: AppTypography.taskTitle),
        trailing: active ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 18) : null,
        onTap: () {
          ref.read(activeCategoryProvider.notifier).set(categoryKey);
          context.pop();
        },
      ),
    );
  }
}
