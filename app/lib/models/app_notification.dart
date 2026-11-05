enum AppNotificationType { account, order, promotion, general }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final AppNotificationType type;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type = AppNotificationType.general,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: AppNotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AppNotificationType.general,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
