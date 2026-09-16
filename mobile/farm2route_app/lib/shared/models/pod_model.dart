class PodModel {
  final String id;
  final String bookingId;
  final String? bookingNumber;
  final String? driverId;
  final String? driverName;
  final String recipientName;
  final String recipientPhone;
  final String? recipientSignatureUrl;
  final String? deliveryPhotoUrl;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final DateTime? deliveryTimestamp;
  final String? farmerConfirmationStatus;
  final DateTime? farmerConfirmedAt;
  final String? notes;
  final DateTime? createdAt;

  const PodModel({
    required this.id,
    required this.bookingId,
    this.bookingNumber,
    this.driverId,
    this.driverName,
    required this.recipientName,
    required this.recipientPhone,
    this.recipientSignatureUrl,
    this.deliveryPhotoUrl,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryTimestamp,
    this.farmerConfirmationStatus,
    this.farmerConfirmedAt,
    this.notes,
    this.createdAt,
  });

  factory PodModel.fromJson(Map<String, dynamic> json) {
    return PodModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      bookingNumber: json['bookingNumber']?.toString(),
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString(),
      recipientName: json['recipientName']?.toString() ?? '',
      recipientPhone: json['recipientPhone']?.toString() ?? '',
      recipientSignatureUrl: json['recipientSignatureUrl']?.toString(),
      deliveryPhotoUrl: json['deliveryPhotoUrl']?.toString(),
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      deliveryTimestamp: json['deliveryTimestamp'] != null
          ? DateTime.tryParse(json['deliveryTimestamp'].toString())
          : null,
      farmerConfirmationStatus: json['farmerConfirmationStatus']?.toString(),
      farmerConfirmedAt: json['farmerConfirmedAt'] != null
          ? DateTime.tryParse(json['farmerConfirmedAt'].toString())
          : null,
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'driverId': driverId,
      'driverName': driverName,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientSignatureUrl': recipientSignatureUrl,
      'deliveryPhotoUrl': deliveryPhotoUrl,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryTimestamp': deliveryTimestamp?.toIso8601String(),
      'farmerConfirmationStatus': farmerConfirmationStatus,
      'farmerConfirmedAt': farmerConfirmedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
