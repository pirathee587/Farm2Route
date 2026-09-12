// ==============================================================================
// Farmer Dashboard Domain Models
// ==============================================================================

class DispatchAvailabilitySlot {
  final DateTime date;
  final int availableSlots;
  final int maxSlots;
  final bool isFullyBooked;

  const DispatchAvailabilitySlot({
    required this.date,
    required this.availableSlots,
    this.maxSlots = 12,
    required this.isFullyBooked,
  });

  factory DispatchAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return DispatchAvailabilitySlot(
      date: DateTime.parse(json['date'] as String),
      availableSlots: json['availableSlots'] as int? ?? 0,
      maxSlots: json['maxSlots'] as int? ?? 12,
      isFullyBooked: json['isFullyBooked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'availableSlots': availableSlots,
        'maxSlots': maxSlots,
        'isFullyBooked': isFullyBooked,
      };
}

class FareEstimateModel {
  final int distanceKm;
  final double estimatedFare;
  final String durationText;

  const FareEstimateModel({
    required this.distanceKm,
    required this.estimatedFare,
    required this.durationText,
  });

  String get formattedFare => 'LKR ${estimatedFare.toStringAsFixed(0)}';

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    return FareEstimateModel(
      distanceKm: json['distanceKm'] as int? ?? 0,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      durationText: json['durationText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'distanceKm': distanceKm,
        'estimatedFare': estimatedFare,
        'durationText': durationText,
      };
}

class HaulerAgencyModel {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final int etaMinutes;
  final double estimatedFare;
  final String? promoBadge;
  final String vehicleType;
  final String vehiclePlate;
  final String phone;
  final bool coldChainSupported;

  const HaulerAgencyModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.etaMinutes,
    required this.estimatedFare,
    this.promoBadge,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.phone,
    this.coldChainSupported = false,
  });

  String get formattedFare => 'LKR ${estimatedFare.toStringAsFixed(0)}';
  String get etaFormatted => '$etaMinutes min';

  factory HaulerAgencyModel.fromJson(Map<String, dynamic> json) {
    return HaulerAgencyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Logistics Agency',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: json['reviewsCount'] as int? ?? 120,
      etaMinutes: json['etaMinutes'] as int? ?? 25,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 12500.0,
      promoBadge: json['promoBadge'] as String?,
      vehicleType: json['vehicleType'] as String? ?? 'Medium Freight Lorry (6-T)',
      vehiclePlate: json['vehiclePlate'] as String? ?? 'WP-ND-8821',
      phone: json['phone'] as String? ?? '+94 77 123 4567',
      coldChainSupported: json['coldChainSupported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'etaMinutes': etaMinutes,
        'estimatedFare': estimatedFare,
        'promoBadge': promoBadge,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
        'phone': phone,
        'coldChainSupported': coldChainSupported,
      };
}

class FindHaulersRequest {
  final String pickupLocation;
  final String destinationLocation;
  final DateTime dispatchDate;
  final double weightKg;
  final String produceType;
  final bool requiresColdChain;

  const FindHaulersRequest({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.dispatchDate,
    required this.weightKg,
    required this.produceType,
    this.requiresColdChain = false,
  });

  Map<String, dynamic> toJson() => {
        'pickupLocation': pickupLocation,
        'destinationLocation': destinationLocation,
        'dispatchDate': dispatchDate.toIso8601String().split('T').first,
        'weightKg': weightKg,
        'produceType': produceType,
        'requiresColdChain': requiresColdChain,
      };
}

class LogisticsPackageModel {
  final String id;
  final String name;
  final String frequency;
  final double price;
  final String discountBadge;
  final String description;
  final List<String> features;

  const LogisticsPackageModel({
    required this.id,
    required this.name,
    required this.frequency,
    required this.price,
    required this.discountBadge,
    required this.description,
    required this.features,
  });

  String get formattedPrice => 'LKR ${price.toStringAsFixed(0)}';

  factory LogisticsPackageModel.fromJson(Map<String, dynamic> json) {
    return LogisticsPackageModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'Monthly',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountBadge: json['discountBadge'] as String? ?? '',
      description: json['description'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequency': frequency,
        'price': price,
        'discountBadge': discountBadge,
        'description': description,
        'features': features,
      };
}

class FarmerOrderModel {
  final String id;
  final String bookingRef;
  final String pickup;
  final String destination;
  final String produceType;
  final double weightKg;
  final double fare;
  final String status; // 'PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'
  final String date;

  const FarmerOrderModel({
    required this.id,
    required this.bookingRef,
    required this.pickup,
    required this.destination,
    required this.produceType,
    required this.weightKg,
    required this.fare,
    required this.status,
    required this.date,
  });

  String get formattedFare => 'LKR ${fare.toStringAsFixed(0)}';

  factory FarmerOrderModel.fromJson(Map<String, dynamic> json) {
    return FarmerOrderModel(
      id: json['id'] as String? ?? '',
      bookingRef: json['bookingRef'] as String? ?? '',
      pickup: json['pickup'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      produceType: json['produceType'] as String? ?? 'Vegetables',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingRef': bookingRef,
        'pickup': pickup,
        'destination': destination,
        'produceType': produceType,
        'weightKg': weightKg,
        'fare': fare,
        'status': status,
        'date': date,
      };
}

class BookingSubmissionRequest {
  final String pickupLocation;
  final String destinationLocation;
  final DateTime dispatchDate;
  final double weightKg;
  final String produceType;
  final String haulerId;
  final double fare;

  const BookingSubmissionRequest({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.dispatchDate,
    required this.weightKg,
    required this.produceType,
    required this.haulerId,
    required this.fare,
  });

  Map<String, dynamic> toJson() => {
        'pickupLocation': pickupLocation,
        'destinationLocation': destinationLocation,
        'dispatchDate': dispatchDate.toIso8601String().split('T').first,
        'weightKg': weightKg,
        'produceType': produceType,
        'haulerId': haulerId,
        'fare': fare,
      };
}
