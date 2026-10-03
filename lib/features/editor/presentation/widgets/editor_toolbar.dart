import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback onVoiceTap;
  final VoidCallback onImageTap;
  final VoidCallback onDrawingTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onTypographyTap;

  const EditorToolbar({
    super.key,
    required this.onVoiceTap,
    required this.onImageTap,
    required this.onDrawingTap,
    required this.onChecklistTap,
    required this.onTypographyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Audio / Voice Icon (Waveform)
          IconButton(
            icon: const Icon(Icons.graphic_eq_rounded, color: AppColors.iconSecondary, size: 23),
            tooltip: 'Voice note',
            onPressed: onVoiceTap,
          ),

          // 2. Image Icon
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppColors.iconSecondary, size: 23),
            tooltip: 'Add image',
            onPressed: onImageTap,
          ),

          // 3. Drawing Scribble Icon
          IconButton(
            icon: const Icon(Icons.gesture_rounded, color: AppColors.iconSecondary, size: 23),
            tooltip: 'Sketch / Drawing',
            onPressed: onDrawingTap,
          ),

          // 4. Checklist Icon
          IconButton(
            icon: const Icon(Icons.check_box_outlined, color: AppColors.iconSecondary, size: 23),
            tooltip: 'Checklist',
            onPressed: onChecklistTap,
          ),

          // 5. Typography 'T' Icon
          IconButton(
            icon: const Icon(Icons.title_rounded, color: AppColors.iconSecondary, size: 23),
            tooltip: 'Formatting',
            onPressed: onTypographyTap,
          ),
        ],
      ),
    );
  }
}
