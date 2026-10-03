class FolderModel {
  final String id;
  final String userId;
  final String name;
  final String? color;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      color: map['color'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
