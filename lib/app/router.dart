import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/detail/presentation/note_detail_screen.dart';
import '../features/editor/presentation/note_editor_screen.dart';
import '../features/folders/presentation/folders_screen.dart';
import '../features/mind_map/presentation/mind_map_screen.dart';
import '../features/notes/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/vault/presentation/vault_screen.dart';

GoRouter createAppRouter({required bool isAuthenticated}) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/home' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const ResponsiveWrapper(child: LoginScreen()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ResponsiveWrapper(child: HomeScreen()),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return ResponsiveWrapper(child: NoteDetailScreen(noteId: noteId));
        },
      ),
      GoRoute(
        path: '/edit',
        builder: (context, state) => const ResponsiveWrapper(child: NoteEditorScreen()),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id'];
          return ResponsiveWrapper(child: NoteEditorScreen(noteId: noteId));
        },
      ),
      GoRoute(
        path: '/mind-map/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return ResponsiveWrapper(child: MindMapScreen(noteId: noteId));
        },
      ),
      GoRoute(
        path: '/vault',
        builder: (context, state) => const ResponsiveWrapper(child: VaultScreen()),
      ),
      GoRoute(
        path: '/folders',
        builder: (context, state) => const ResponsiveWrapper(child: FoldersScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const ResponsiveWrapper(child: SearchScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const ResponsiveWrapper(child: SettingsScreen()),
      ),
    ],
  );
}

final appRouter = createAppRouter(isAuthenticated: false);

/// Responsive wrapper that constrains desktop / web view to preserve mobile MI Notes proportions
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF242424), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}
