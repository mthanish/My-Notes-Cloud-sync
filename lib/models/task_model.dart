import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority {
  low,
  medium,
  high,
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isPendingSync;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.reminderTime,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isPendingSync = false,
  });

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isPendingSync,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel.fromMap(data, idOverride: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'priority': priority.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
      'isPendingSync': isPendingSync,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, {String? idOverride}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TaskModel(
      id: idOverride ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      dueDate: parseDate(map['dueDate']),
      reminderTime: parseDate(map['reminderTime']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
