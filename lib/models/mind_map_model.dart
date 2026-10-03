import 'package:uuid/uuid.dart';

class MindMapNode {
  final String id;
  String text;
  List<MindMapNode> children;
  bool isExpanded;

  MindMapNode({
    String? id,
    required this.text,
    List<MindMapNode>? children,
    this.isExpanded = true,
  })  : id = id ?? const Uuid().v4(),
        children = children ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isExpanded': isExpanded,
      'children': children.map((c) => c.toMap()).toList(),
    };
  }

  factory MindMapNode.fromMap(Map<String, dynamic> map) {
    return MindMapNode(
      id: map['id'] ?? const Uuid().v4(),
      text: map['text'] ?? '',
      isExpanded: map['isExpanded'] ?? true,
      children: (map['children'] as List<dynamic>?)
              ?.map((c) => MindMapNode.fromMap(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
    );
  }

  MindMapNode clone() {
    return MindMapNode(
      id: id,
      text: text,
      isExpanded: isExpanded,
      children: children.map((c) => c.clone()).toList(),
    );
  }

  // Find a node by ID in the tree
  MindMapNode? findNode(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findNode(targetId);
      if (found != null) return found;
    }
    return null;
  }

  // Find parent of a node
  MindMapNode? findParent(String targetId) {
    for (final child in children) {
      if (child.id == targetId) return this;
      final found = child.findParent(targetId);
      if (found != null) return found;
    }
    return null;
  }

  // Add child
  void addChild(String childText) {
    children.add(MindMapNode(text: childText));
  }

  // Delete child
  bool removeChild(String targetId) {
    final initialLength = children.length;
    children.removeWhere((c) => c.id == targetId);
    if (children.length < initialLength) return true;
    for (final child in children) {
      if (child.removeChild(targetId)) return true;
    }
    return false;
  }
}
