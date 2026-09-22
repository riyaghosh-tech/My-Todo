class Task {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime createdAt;

  final String? location;
  final DateTime? dueDateTime;
  final int notificationId;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.location,
    this.dueDateTime,
    required this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'dueDateTime': dueDateTime?.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      location: map['location'],
      dueDateTime: map['dueDateTime'] == null
          ? null
          : DateTime.tryParse(map['dueDateTime'].toString()),
      notificationId: map['notificationId'] is int
          ? map['notificationId']
          : DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}