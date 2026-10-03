import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  text,
  checklist,
  image,
  drawing,
  vault,
  mindMap,
}

class ChecklistItem {
  final String id;
  final String title;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? id, String? title, bool? isDone}) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }
}

class NoteAttachment {
  final String id;
  final String url;
  final String name;
  final String type; // 'image', 'drawing', 'file'

  const NoteAttachment({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'type': type,
    };
  }

  factory NoteAttachment.fromMap(Map<String, dynamic> map) {
    return NoteAttachment(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'image',
    );
  }
}

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final NoteType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final String? folderId;
  final String category; // 'notes', 'passwords', 'Uncategorised', etc.
  final String? color;
  final List<NoteAttachment> attachments;
  final List<ChecklistItem> checklistItems;
  final Map<String, dynamic>? mindMapData;
  final int syncVersion;
  final bool isPendingSync;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.type = NoteType.text,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.folderId,
    this.category = 'notes',
    this.color,
    this.attachments = const [],
    this.checklistItems = const [],
    this.mindMapData,
    this.syncVersion = 1,
    this.isPendingSync = false,
  });

  int get characterCount => content.length;

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    NoteType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    String? folderId,
    String? category,
    String? color,
    List<NoteAttachment>? attachments,
    List<ChecklistItem>? checklistItems,
    Map<String, dynamic>? mindMapData,
    int? syncVersion,
    bool? isPendingSync,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      folderId: folderId ?? this.folderId,
      category: category ?? this.category,
      color: color ?? this.color,
      attachments: attachments ?? this.attachments,
      checklistItems: checklistItems ?? this.checklistItems,
      mindMapData: mindMapData ?? this.mindMapData,
      syncVersion: syncVersion ?? this.syncVersion,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'folderId': folderId,
      'category': category,
      'color': color,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'checklistItems': checklistItems.map((c) => c.toMap()).toList(),
      'mindMapData': mindMapData,
      'syncVersion': syncVersion,
    };
  }

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel.fromMap(data, idOverride: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'folderId': folderId,
      'category': category,
      'color': color,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'checklistItems': checklistItems.map((c) => c.toMap()).toList(),
      'mindMapData': mindMapData,
      'syncVersion': syncVersion,
      'isPendingSync': isPendingSync,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, {String? idOverride}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NoteModel(
      id: idOverride ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NoteType.text,
      ),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      folderId: map['folderId'],
      category: map['category'] ?? 'notes',
      color: map['color'],
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((e) => NoteAttachment.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      checklistItems: (map['checklistItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      mindMapData: map['mindMapData'] != null
          ? Map<String, dynamic>.from(map['mindMapData'])
          : null,
      syncVersion: map['syncVersion'] ?? 1,
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
