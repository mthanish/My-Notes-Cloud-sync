import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/mind_map_model.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final String noteId;

  const MindMapScreen({super.key, required this.noteId});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen> {
  late MindMapNode _rootNode;
  String? _selectedNodeId;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _rootNode = MindMapNode(text: 'Central Idea');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(notesRepositoryProvider);
      final note = repo.getNoteById(widget.noteId);
      if (note != null && note.mindMapData != null) {
        setState(() {
          _rootNode = MindMapNode.fromMap(note.mindMapData!);
          _selectedNodeId = _rootNode.id;
        });
      } else {
        _selectedNodeId = _rootNode.id;
      }
    });
  }

  void _saveMindMap() {
    final repo = ref.read(notesRepositoryProvider);
    final note = repo.getNoteById(widget.noteId);
    if (note != null) {
      final updated = note.copyWith(
        mindMapData: _rootNode.toMap(),
        updatedAt: DateTime.now(),
      );
      repo.saveNote(updated);
    }
  }

  void _addChildNode() {
    if (_selectedNodeId == null) return;
    final node = _rootNode.findNode(_selectedNodeId!);
    if (node != null) {
      _showEditDialog(
        title: 'Add Sub-topic',
        initialText: 'New topic',
        onConfirm: (text) {
          setState(() {
            node.addChild(text);
          });
          _saveMindMap();
        },
      );
    }
  }

  void _addSiblingNode() {
    if (_selectedNodeId == null || _selectedNodeId == _rootNode.id) {
      _addChildNode();
      return;
    }
    final parent = _rootNode.findParent(_selectedNodeId!);
    if (parent != null) {
      _showEditDialog(
        title: 'Add Topic',
        initialText: 'New topic',
        onConfirm: (text) {
          setState(() {
            parent.addChild(text);
          });
          _saveMindMap();
        },
      );
    }
  }

  void _deleteSelectedNode() {
    if (_selectedNodeId == null || _selectedNodeId == _rootNode.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the root node')),
      );
      return;
    }
    setState(() {
      _rootNode.removeChild(_selectedNodeId!);
      _selectedNodeId = _rootNode.id;
    });
    _saveMindMap();
  }

  void _editSelectedNode() {
    if (_selectedNodeId == null) return;
    final node = _rootNode.findNode(_selectedNodeId!);
    if (node != null) {
      _showEditDialog(
        title: 'Edit Topic',
        initialText: node.text,
        onConfirm: (text) {
          setState(() {
            node.text = text;
          });
          _saveMindMap();
        },
      );
    }
  }

  void _showEditDialog({
    required String title,
    required String initialText,
    required ValueChanged<String> onConfirm,
  }) {
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onConfirm(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Interactive Mind Map Canvas (Pan & Zoom)
          InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(1000),
            minScale: 0.3,
            maxScale: 2.5,
            child: Container(
              width: 2400,
              height: 2400,
              color: AppColors.background,
              child: CustomPaint(
                painter: _MindMapTreePainter(
                  root: _rootNode,
                  selectedId: _selectedNodeId,
                ),
                child: _buildInteractiveNodesOverlay(),
              ),
            ),
          ),

          // Top Action Header (Back, View mode, Menu)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circularButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      _saveMindMap();
                      context.pop();
                    },
                  ),
                  const Spacer(),
                  _circularButton(
                    icon: Icons.format_list_bulleted_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mind map list mode')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _circularButton(
                    icon: Icons.more_vert_rounded,
                    onTap: () {
                      _editSelectedNode();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons matching screenshot
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: SafeArea(
              child: Row(
                children: [
                  // Delete Button
                  _circularButton(
                    icon: Icons.delete_outline_rounded,
                    size: 52,
                    iconSize: 24,
                    color: Colors.white.withValues(alpha: 0.9),
                    onTap: _deleteSelectedNode,
                  ),

                  const Spacer(),

                  // Add Child Button
                  _circularButton(
                    icon: Icons.add_circle_outline_rounded,
                    size: 52,
                    iconSize: 24,
                    color: Colors.white.withValues(alpha: 0.9),
                    onTap: _addChildNode,
                  ),

                  const SizedBox(width: 14),

                  // Add Sibling Button
                  _circularButton(
                    icon: Icons.alt_route_rounded,
                    size: 52,
                    iconSize: 24,
                    color: Colors.white.withValues(alpha: 0.9),
                    onTap: _addSiblingNode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
    double iconSize = 20,
    Color color = AppColors.iconPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF222222),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildInteractiveNodesOverlay() {
    // Collect all nodes with calculated coordinates
    final nodes = <_CalculatedNode>[];
    _layoutTree(_rootNode, const Offset(300, 1200), nodes);

    return Stack(
      children: nodes.map((node) {
        final isSelected = node.node.id == _selectedNodeId;
        final isRoot = node.node.id == _rootNode.id;

        return Positioned(
          left: node.position.dx,
          top: node.position.dy - (isRoot ? 18 : 14),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedNodeId = node.node.id);
            },
            onDoubleTap: () {
              setState(() => _selectedNodeId = node.node.id);
              _editSelectedNode();
            },
            child: isRoot
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Text(
                      node.node.text,
                      style: AppTypography.mindMapRoot,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      node.node.text,
                      style: AppTypography.mindMapBranch.copyWith(
                        color: isSelected ? AppColors.accent : Colors.white,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  double _layoutTree(MindMapNode node, Offset pos, List<_CalculatedNode> result) {
    result.add(_CalculatedNode(node: node, position: pos));
    if (node.children.isEmpty) {
      return 40.0;
    }

    double totalHeight = 0;
    final childHeights = <double>[];
    for (final child in node.children) {
      final h = _calcSubtreeHeight(child);
      childHeights.add(h);
      totalHeight += h;
    }

    double currentY = pos.dy - (totalHeight / 2);
    final childX = pos.dx + (node.id == _rootNode.id ? 200 : 160);

    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final h = childHeights[i];
      final childY = currentY + (h / 2);
      _layoutTree(child, Offset(childX, childY), result);
      currentY += h;
    }

    return totalHeight;
  }

  double _calcSubtreeHeight(MindMapNode node) {
    if (node.children.isEmpty) return 40.0;
    double h = 0;
    for (final child in node.children) {
      h += _calcSubtreeHeight(child);
    }
    return math.max(h, 40.0);
  }
}

class _CalculatedNode {
  final MindMapNode node;
  final Offset position;
  _CalculatedNode({required this.node, required this.position});
}

class _MindMapTreePainter extends CustomPainter {
  final MindMapNode root;
  final String? selectedId;

  _MindMapTreePainter({required this.root, required this.selectedId});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final underlinePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    _drawTree(canvas, root, const Offset(300, 1200), linePaint, underlinePaint);
  }

  double _drawTree(
    Canvas canvas,
    MindMapNode node,
    Offset pos,
    Paint linePaint,
    Paint underlinePaint,
  ) {
    final isRoot = node.id == root.id;
    final nodeWidth = isRoot ? 140.0 : (node.text.length * 8.0 + 16.0);

    // Draw underline for subnodes matching screenshot!
    if (!isRoot) {
      canvas.drawLine(
        Offset(pos.dx, pos.dy + 12),
        Offset(pos.dx + nodeWidth, pos.dy + 12),
        underlinePaint,
      );
    }

    if (node.children.isEmpty) return 40.0;

    double totalHeight = 0;
    final childHeights = <double>[];
    for (final child in node.children) {
      final h = _calcSubtreeHeight(child);
      childHeights.add(h);
      totalHeight += h;
    }

    double currentY = pos.dy - (totalHeight / 2);
    final startX = pos.dx + nodeWidth;
    final childX = pos.dx + (isRoot ? 200 : 160);

    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final h = childHeights[i];
      final childY = currentY + (h / 2);

      // Smooth curved cubic bezier connecting branch
      final path = Path()
        ..moveTo(startX, isRoot ? pos.dy : pos.dy + 12)
        ..cubicTo(
          startX + (childX - startX) * 0.5,
          isRoot ? pos.dy : pos.dy + 12,
          startX + (childX - startX) * 0.5,
          childY + 12,
          childX,
          childY + 12,
        );

      canvas.drawPath(path, linePaint);

      _drawTree(canvas, child, Offset(childX, childY), linePaint, underlinePaint);
      currentY += h;
    }

    return totalHeight;
  }

  double _calcSubtreeHeight(MindMapNode node) {
    if (node.children.isEmpty) return 40.0;
    double h = 0;
    for (final child in node.children) {
      h += _calcSubtreeHeight(child);
    }
    return math.max(h, 40.0);
  }

  @override
  bool shouldRepaint(covariant _MindMapTreePainter oldDelegate) => true;
}
