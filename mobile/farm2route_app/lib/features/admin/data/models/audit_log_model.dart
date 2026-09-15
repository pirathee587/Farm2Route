class AuditLogModel {
  final String id;
  final String? actorId;
  final String? actorRole;
  final String action;
  final String entityName;
  final String? entityId;
  final String? oldValue;
  final String? newValue;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  const AuditLogModel({
    required this.id,
    this.actorId,
    this.actorRole,
    required this.action,
    required this.entityName,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      actorId: json['actorId']?.toString(),
      actorRole: json['actorRole']?.toString(),
      action: json['action']?.toString() ?? '',
      entityName: json['entityName']?.toString() ?? '',
      entityId: json['entityId']?.toString(),
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      userAgent: json['userAgent']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorId': actorId,
      'actorRole': actorRole,
      'action': action,
      'entityName': entityName,
      'entityId': entityId,
      'oldValue': oldValue,
      'newValue': newValue,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class PagedAuditLogModel {
  final List<AuditLogModel> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PagedAuditLogModel({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PagedAuditLogModel.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>? ?? [];
    return PagedAuditLogModel(
      content: list
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      last: json['last'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((e) => e.toJson()).toList(),
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalElements': totalElements,
      'totalPages': totalPages,
      'last': last,
    };
  }
}
