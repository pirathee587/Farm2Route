class TransportPackageModel {
  final String id;
  final String agencyName;
  final double rating;
  final int reviewCount;
  final String pickupLocation;
  final String deliveryMarket;
  final double pricePerKg;
  final String vehicleType;
  final int maxWeightKg;
  final int availableTrucks;
  final double distanceKm;
  final String status; // "ACTIVE" | "INACTIVE"
  final String category; // "Express Haul" | "Harvest Transport" | "Bulk Cargo" | "Refrigerated"
  final bool hasOffer;
  final String? offerLabel;

  const TransportPackageModel({
    required this.id,
    required this.agencyName,
    required this.rating,
    required this.reviewCount,
    required this.pickupLocation,
    required this.deliveryMarket,
    required this.pricePerKg,
    required this.vehicleType,
    required this.maxWeightKg,
    required this.availableTrucks,
    required this.distanceKm,
    this.status = 'ACTIVE',
    required this.category,
    this.hasOffer = false,
    this.offerLabel,
  });

  factory TransportPackageModel.fromJson(Map<String, dynamic> json) {
    return TransportPackageModel(
      id: json['id'] as String? ?? '',
      agencyName: json['agencyName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      pickupLocation: json['pickupLocation'] as String? ?? '',
      deliveryMarket: json['deliveryMarket'] as String? ?? '',
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      vehicleType: json['vehicleType'] as String? ?? '',
      maxWeightKg: (json['maxWeightKg'] as num?)?.toInt() ?? 0,
      availableTrucks: (json['availableTrucks'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
      category: json['category'] as String? ?? 'Bulk Cargo',
      hasOffer: json['hasOffer'] as bool? ?? false,
      offerLabel: json['offerLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agencyName': agencyName,
      'rating': rating,
      'reviewCount': reviewCount,
      'pickupLocation': pickupLocation,
      'deliveryMarket': deliveryMarket,
      'pricePerKg': pricePerKg,
      'vehicleType': vehicleType,
      'maxWeightKg': maxWeightKg,
      'availableTrucks': availableTrucks,
      'distanceKm': distanceKm,
      'status': status,
      'category': category,
      'hasOffer': hasOffer,
      'offerLabel': offerLabel,
    };
  }
}
