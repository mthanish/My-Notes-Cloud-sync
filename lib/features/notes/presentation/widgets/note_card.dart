import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/mi_icons.dart';
import '../../../../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = note.content.trim().isNotEmpty;
    final isVault = note.type == NoteType.vault || note.category == 'passwords';
    final isMindMap = note.type == NoteType.mindMap;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0x15FFFFFF),
        highlightColor: const Color(0x10FFFFFF),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Note Title
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: AppTypography.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],

              // Note Body / Preview
              if (hasContent) ...[
                Text(
                  isVault ? 'Protected password note' : note.content,
                  style: AppTypography.cardBody.copyWith(
                    fontStyle: isVault ? FontStyle.italic : FontStyle.normal,
                    color: isVault ? AppColors.textTertiary : AppColors.textSecondary,
                  ),
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Footer: Date + Status Badges (Pin, Key, MindMap)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatCardDate(note.updatedAt),
                    style: AppTypography.cardDate,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isPinned) ...[
                        MiIcons.pinStar(size: 13, color: AppColors.accent),
                        const SizedBox(width: 4),
                      ],
                      if (isVault) ...[
                        MiIcons.vaultKey(size: 13, color: AppColors.accent),
                      ] else if (isMindMap) ...[
                        const Icon(
                          Icons.account_tree_outlined,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
