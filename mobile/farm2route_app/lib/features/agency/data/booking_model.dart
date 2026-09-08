class BookingModel {
  final String id;
  final String bookingNumber;
  final String packageId;
  final String packageName;
  final String pickupAddress;
  final String deliveryAddress;
  final String pickupContactName;
  final String deliveryRecipientName;
  final String cargoType;
  final String cargoWeightKg;
  final String totalAmount;
  final String status;
  final String scheduledPickupAt;
  final String createdAt;
  final String driverId;
  final String vehicleId;
  final String cancellationReason;
  final bool requiresRefrigeration;
  final bool fragile;

  const BookingModel(
      {required this.id,
      required this.bookingNumber,
      required this.packageId,
      required this.packageName,
      required this.pickupAddress,
      required this.deliveryAddress,
      required this.pickupContactName,
      required this.deliveryRecipientName,
      required this.cargoType,
      required this.cargoWeightKg,
      required this.totalAmount,
      required this.status,
      required this.scheduledPickupAt,
      required this.createdAt,
      required this.driverId,
      required this.vehicleId,
      required this.cancellationReason,
      required this.requiresRefrigeration,
      required this.fragile});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: '${json['id'] ?? ''}',
        bookingNumber: '${json['bookingNumber'] ?? ''}',
        packageId: '${json['packageId'] ?? ''}',
        packageName: '${json['packageName'] ?? ''}',
        pickupAddress: '${json['pickupAddress'] ?? ''}',
        deliveryAddress: '${json['deliveryAddress'] ?? ''}',
        pickupContactName: '${json['pickupContactName'] ?? ''}',
        deliveryRecipientName: '${json['recipientName'] ?? ''}',
        cargoType: '${json['cargoType'] ?? ''}',
        cargoWeightKg: '${json['cargoWeightKg'] ?? ''}',
        totalAmount: '${json['totalAmount'] ?? ''}',
        status: '${json['status'] ?? 'UNKNOWN'}',
        scheduledPickupAt: '${json['scheduledPickupAt'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
        driverId: '${json['driverId'] ?? ''}',
        vehicleId: '${json['vehicleId'] ?? ''}',
        cancellationReason: '${json['cancellationReason'] ?? ''}',
        requiresRefrigeration: json['requiresRefrigeration'] == true,
        fragile: json['fragile'] == true || json['isFragile'] == true,
      );
}
