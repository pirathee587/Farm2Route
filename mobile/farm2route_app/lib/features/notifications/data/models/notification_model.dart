class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final String? referenceType;
  final String? referenceId;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.referenceType,
    this.referenceId,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      notificationType: json['notificationType'] as String? ?? 'SYSTEM',
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'notificationType': notificationType,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'read': read,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? notificationType,
    String? referenceType,
    String? referenceId,
    bool? read,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
