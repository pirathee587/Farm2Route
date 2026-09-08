// ==============================================================================
// Farmer Dashboard Repository Interface
// ==============================================================================

import '../../data/models/farmer_dashboard_models.dart';

abstract class FarmerDashboardRepository {
  /// Fetches dispatch slots and availability counts for given month/year
  Future<List<DispatchAvailabilitySlot>> checkAvailability(DateTime month);

  /// Estimates distance and trip fare based on origin, destination, weight, and crop type
  Future<FareEstimateModel> estimateFare({
    required String pickup,
    required String destination,
    required double weightKg,
    required String produceType,
  });

  /// Finds matching haulers/agencies for the specified booking criteria
  Future<List<HaulerAgencyModel>> findHaulers(FindHaulersRequest request);

  /// Fetches featured subscription packages for farmers
  Future<List<LogisticsPackageModel>> getPackages();

  /// Subscribes farmer to a selected logistics package
  Future<bool> subscribeToPackage(String farmerId, String packageId);

  /// Submits and confirms an agricultural freight booking
  Future<FarmerOrderModel> createBooking(BookingSubmissionRequest request);

  /// Fetches recent bookings made by the farmer
  Future<List<FarmerOrderModel>> getRecentOrders();
}
