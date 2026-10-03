import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import 'mi_icons.dart';

class EmptyStateView extends StatelessWidget {
  final bool isTasks;
  final String? message;

  const EmptyStateView({
    super.key,
    this.isTasks = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final text = message ?? (isTasks ? 'No tasks here yet' : 'No notes here yet');

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTasks)
              MiIcons.emptyTasksGraphic(size: 74)
            else
              MiIcons.emptyNotesGraphic(size: 74),
            const SizedBox(height: 18),
            Text(
              text,
              style: AppTypography.emptyStateText.copyWith(
                color: const Color(0xFF7E7E7E),
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
