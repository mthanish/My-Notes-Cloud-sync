import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/mi_icons.dart';

class CategoryChipsBar extends ConsumerWidget {
  final VoidCallback onFolderTap;

  const CategoryChipsBar({
    super.key,
    required this.onFolderTap,
  });

  static const List<String> defaultCategories = [
    'All',
    'notes',
    'passwords',
    'Uncategorised',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(activeCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: defaultCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == defaultCategories.length) {
            // Folder chip on the right
            return GestureDetector(
              onTap: onFolderTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.chipBackgroundUnselected,
                  borderRadius: BorderRadius.circular(19),
                ),
                alignment: Alignment.center,
                child: MiIcons.folder(size: 16, color: AppColors.accent),
              ),
            );
          }

          final category = defaultCategories[index];
          final isSelected = activeCategory == category;

          return GestureDetector(
            onTap: () {
              ref.read(activeCategoryProvider.notifier).set(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.chipBackgroundSelected
                    : AppColors.chipBackgroundUnselected,
                borderRadius: BorderRadius.circular(19),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: isSelected ? AppTypography.chipSelected : AppTypography.chipUnselected,
              ),
            ),
          );
        },
      ),
    );
  }
}
