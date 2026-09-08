class AssignmentRecommendationModel {
  final String bookingId;
  final String? recommendedDriverId;
  final String? recommendedDriverName;
  final double? recommendedDriverRating;
  final String? recommendedDriverAvailability;
  final String? recommendedVehicleId;
  final String? recommendedVehicleRegistrationNumber;
  final String? recommendedVehicleMakeAndModel;
  final String? recommendedVehicleCapacity;
  final String? recommendedVehicleType;
  final double? matchScore;
  final String? rationale;

  const AssignmentRecommendationModel(
      {required this.bookingId,
      this.recommendedDriverId,
      this.recommendedDriverName,
      this.recommendedDriverRating,
      this.recommendedDriverAvailability,
      this.recommendedVehicleId,
      this.recommendedVehicleRegistrationNumber,
      this.recommendedVehicleMakeAndModel,
      this.recommendedVehicleCapacity,
      this.recommendedVehicleType,
      this.matchScore,
      this.rationale});

  factory AssignmentRecommendationModel.fromJson(Map<String, dynamic> json) =>
      AssignmentRecommendationModel(
        bookingId: '${json['bookingId'] ?? ''}',
        recommendedDriverId: json['recommendedDriverId']?.toString(),
        recommendedDriverName: json['recommendedDriverName']?.toString(),
        recommendedDriverRating:
            (json['recommendedDriverRating'] as num?)?.toDouble(),
        recommendedDriverAvailability:
            json['recommendedDriverAvailability']?.toString(),
        recommendedVehicleId: json['recommendedVehicleId']?.toString(),
        recommendedVehicleRegistrationNumber:
            json['recommendedVehicleRegistrationNumber']?.toString(),
        recommendedVehicleMakeAndModel:
            json['recommendedVehicleMakeAndModel']?.toString(),
        recommendedVehicleCapacity:
            json['recommendedVehicleCapacity']?.toString(),
        recommendedVehicleType: json['recommendedVehicleType']?.toString(),
        matchScore: (json['matchScore'] as num?)?.toDouble(),
        rationale: json['rationale']?.toString(),
      );
}
