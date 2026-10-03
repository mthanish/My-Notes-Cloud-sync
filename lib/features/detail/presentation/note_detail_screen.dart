import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/mi_icons.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(notesRepositoryProvider);
    final note = repo.getNoteById(noteId);

    if (note == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Note not found',
            style: AppTypography.cardBody,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.iconPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Share Tray Button
          IconButton(
            icon: MiIcons.shareTray(size: 20, color: AppColors.iconPrimary),
            tooltip: 'Share Note',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${note.title}\n\n${note.content}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note copied to clipboard for sharing'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Theme / Shirt Button
          IconButton(
            icon: MiIcons.shirtTheme(size: 20, color: AppColors.iconPrimary),
            tooltip: 'Theme',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Default Dark Theme active'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Overflow Menu (⋮)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.iconPrimary, size: 22),
            color: AppColors.dialogBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/edit/${note.id}');
              } else if (value == 'pin') {
                await repo.togglePin(note.id);
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.dialogBackground,
                    title: const Text('Delete note?'),
                    content: const Text('This note will be moved to trash and synchronized.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await repo.deleteNote(note.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.iconSecondary),
                    SizedBox(width: 10),
                    Text('Edit Note', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      note.isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 18,
                      color: note.isPinned ? AppColors.accent : AppColors.iconSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      note.isPinned ? 'Unpin Note' : 'Pin Note',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Tap anywhere to transition into editor
          context.push('/edit/${note.id}');
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title matching screenshot
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: AppTypography.noteDetailTitle,
                ),
              const SizedBox(height: 8),

              // Metadata line ("11 September 9:23 PM | 18598 characters")
              Text(
                DateFormatter.formatDetailHeader(note.updatedAt, note.characterCount),
                style: AppTypography.noteMetadata,
              ),
              const SizedBox(height: 24),

              // Body content with typography matching screenshot
              Text(
                note.content,
                style: AppTypography.noteBody,
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // Floating Edit button for accessibility
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        elevation: 0,
        onPressed: () => context.push('/edit/${note.id}'),
        child: const Icon(Icons.edit_rounded, color: Colors.black, size: 24),
      ),
    );
  }
}
