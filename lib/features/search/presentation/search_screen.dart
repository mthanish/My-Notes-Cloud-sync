import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../notes/presentation/widgets/note_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);
    final repo = ref.watch(notesRepositoryProvider);
    final allNotes = notesAsync.value ?? repo.getNotes();

    final filtered = _query.trim().isEmpty
        ? []
        : allNotes.where((note) {
            final q = _query.toLowerCase();
            return note.title.toLowerCase().contains(q) ||
                note.content.toLowerCase().contains(q) ||
                note.category.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.chipBackgroundUnselected,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
            cursorColor: AppColors.accent,
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: 'Search notes, categories, tags...',
              hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14.5),
              border: InputBorder.none,
              isDense: true,
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.iconSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? Center(
              child: Text(
                'Type to search in your notes',
                style: AppTypography.cardBody.copyWith(color: AppColors.textTertiary),
              ),
            )
          : filtered.isEmpty
              ? Center(
                  child: Text(
                    'No results for "$_query"',
                    style: AppTypography.cardBody.copyWith(color: AppColors.textTertiary),
                  ),
                )
              : MasonryGridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    return NoteCard(
                      note: note,
                      onTap: () => context.push('/detail/${note.id}'),
                    );
                  },
                ),
    );
  }
}
