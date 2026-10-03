import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../models/mind_map_model.dart';
import '../../../models/note_model.dart';
import '../../tasks/presentation/tasks_screen.dart';
import 'widgets/category_chips_bar.dart';
import 'widgets/note_card.dart';
import 'widgets/top_header_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showNewNoteOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Create New',
                style: AppTypography.cardTitle.copyWith(fontSize: 18),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notes_rounded, color: AppColors.accent, size: 22),
              ),
              title: const Text('Text Note', style: AppTypography.taskTitle),
              subtitle: const Text('Jot down thoughts, ideas, or lists', style: AppTypography.cardDate),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/edit');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree_outlined, color: AppColors.accent, size: 22),
              ),
              title: const Text('Mind Map', style: AppTypography.taskTitle),
              subtitle: const Text('Visual branching node tree for ideas', style: AppTypography.cardDate),
              onTap: () {
                Navigator.pop(ctx);
                final auth = ref.read(authServiceProvider);
                final newId = const Uuid().v4();
                final rootNode = MindMapNode(text: 'Central Idea');
                final note = NoteModel(
                  id: newId,
                  userId: auth.currentUid,
                  title: 'New Mind Map',
                  content: 'Mind map node tree',
                  type: NoteType.mindMap,
                  mindMapData: rootNode.toMap(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                ref.read(notesRepositoryProvider).saveNote(note);
                context.push('/mind-map/$newId');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 22),
              ),
              title: const Text('Password Vault Item', style: AppTypography.taskTitle),
              subtitle: const Text('Encrypted sensitive credentials note', style: AppTypography.cardDate),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/vault');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final activeCategory = ref.watch(activeCategoryProvider);
    final notesAsync = ref.watch(notesStreamProvider);
    final repo = ref.watch(notesRepositoryProvider);
    final allNotes = notesAsync.value ?? repo.getNotes();

    // Filter notes based on active category
    final filteredNotes = allNotes.where((note) {
      if (activeCategory == 'All') return true;
      return note.category.toLowerCase() == activeCategory.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar matching screenshot
            TopHeaderBar(
              onSettingsTap: () => context.push('/settings'),
              onSearchTap: () => context.push('/search'),
            ),

            // Tab 0: Notes | Tab 1: Tasks
            if (activeTab == 0) ...[
              const SizedBox(height: 4),
              // Category Filter Chips
              CategoryChipsBar(
                onFolderTap: () => context.push('/folders'),
              ),
              const SizedBox(height: 10),

              // Masonry Staggered Grid of Note Cards with Pull-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.dialogBackground,
                  onRefresh: () async {
                    final auth = ref.read(authServiceProvider);
                    if (auth.currentUid != 'guest_user') {
                      try {
                        await ref.read(syncServiceProvider).syncPendingWrites(auth.currentUid);
                      } catch (_) {}
                    }
                    ref.read(notesRepositoryProvider).refresh();
                  },
                  child: filteredNotes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: const [
                            SizedBox(height: 100),
                            EmptyStateView(isTasks: false),
                          ],
                        )
                      : MasonryGridView.count(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          itemCount: filteredNotes.length,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return NoteCard(
                              note: note,
                              onTap: () {
                                if (note.type == NoteType.mindMap) {
                                  context.push('/mind-map/${note.id}');
                                } else if (note.type == NoteType.vault) {
                                  context.push('/vault');
                                } else {
                                  context.push('/detail/${note.id}');
                                }
                              },
                              onLongPress: () {
                                _showNoteOptions(context, ref, note);
                              },
                            );
                          },
                        ),
                ),
              ),
            ] else ...[
              // Tasks Screen Tab
              const Expanded(
                child: TasksScreen(),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: activeTab == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              onPressed: () => _showNewNoteOptions(context, ref),
              child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
            )
          : null, // Tasks screen provides its own FAB
    );
  }

  void _showNoteOptions(BuildContext context, WidgetRef ref, NoteModel note) {
    final repo = ref.read(notesRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                color: note.isPinned ? AppColors.accent : AppColors.iconSecondary,
              ),
              title: Text(
                note.isPinned ? 'Unpin note' : 'Pin note to top',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                repo.togglePin(note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: AppColors.iconSecondary),
              title: const Text('Change category', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showMoveCategoryDialog(context, ref, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete note', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                repo.deleteNote(note.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveCategoryDialog(BuildContext context, WidgetRef ref, NoteModel note) {
    final categories = ['notes', 'passwords', 'Uncategorised', 'Personal', 'Work'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Move to Category', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat, style: const TextStyle(color: AppColors.textPrimary)),
              trailing: note.category == cat ? const Icon(Icons.check_rounded, color: AppColors.accent) : null,
              onTap: () {
                ref.read(notesRepositoryProvider).moveNoteCategory(note.id, cat);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
