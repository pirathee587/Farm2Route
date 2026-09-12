// ==============================================================================
// Farmer Dashboard Riverpod Providers & State Notifiers
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/farmer_dashboard_models.dart';
import '../../data/repositories/farmer_dashboard_repository_impl.dart';
import '../../domain/repositories/farmer_dashboard_repository.dart';

/// Repository Provider
final farmerDashboardRepositoryProvider = Provider<FarmerDashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return FarmerDashboardRepositoryImpl(client);
});

/// Featured Packages Provider
final featuredPackagesProvider = FutureProvider<List<LogisticsPackageModel>>((ref) async {
  final repo = ref.watch(farmerDashboardRepositoryProvider);
  return repo.getPackages();
});

/// Recent Orders Provider
final recentOrdersProvider = FutureProvider<List<FarmerOrderModel>>((ref) async {
  final repo = ref.watch(farmerDashboardRepositoryProvider);
  return repo.getRecentOrders();
});

/// Availability Slots by Month Provider
final dispatchMonthAvailabilityProvider =
    FutureProvider.family<List<DispatchAvailabilitySlot>, DateTime>((ref, month) async {
  final repo = ref.watch(farmerDashboardRepositoryProvider);
  return repo.checkAvailability(month);
});

// ==============================================================================
// Booking Form State & Notifier
// ==============================================================================

class BookingFormState {
  final String pickupLocation;
  final String destinationLocation;
  final DateTime dispatchDate;
  final double weight;
  final String weightUnit; // 'kg' or 'tons'
  final String produceType;
  final bool requiresColdChain;
  final FareEstimateModel? fareEstimate;
  final bool isEstimatingFare;
  final bool isSearching;
  final String? errorMessage;

  const BookingFormState({
    this.pickupLocation = 'My Farm, Dambulla',
    this.destinationLocation = 'Manning Wholesale Market, Colombo',
    required this.dispatchDate,
    this.weight = 1500,
    this.weightUnit = 'kg',
    this.produceType = 'VEGETABLES',
    this.requiresColdChain = false,
    this.fareEstimate,
    this.isEstimatingFare = false,
    this.isSearching = false,
    this.errorMessage,
  });

  double get weightInKg => weightUnit == 'tons' ? weight * 1000 : weight;

  BookingFormState copyWith({
    String? pickupLocation,
    String? destinationLocation,
    DateTime? dispatchDate,
    double? weight,
    String? weightUnit,
    String? produceType,
    bool? requiresColdChain,
    FareEstimateModel? fareEstimate,
    bool? isEstimatingFare,
    bool? isSearching,
    String? errorMessage,
  }) {
    return BookingFormState(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      produceType: produceType ?? this.produceType,
      requiresColdChain: requiresColdChain ?? this.requiresColdChain,
      fareEstimate: fareEstimate ?? this.fareEstimate,
      isEstimatingFare: isEstimatingFare ?? this.isEstimatingFare,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class BookingFormNotifier extends StateNotifier<BookingFormState> {
  final FarmerDashboardRepository _repository;

  BookingFormNotifier(this._repository)
      : super(BookingFormState(
          dispatchDate: DateTime.now().add(const Duration(days: 1)),
        )) {
    recalculateEstimate();
  }

  void setPickupLocation(String pickup) {
    state = state.copyWith(pickupLocation: pickup);
    recalculateEstimate();
  }

  void setDestinationLocation(String destination) {
    state = state.copyWith(destinationLocation: destination);
    recalculateEstimate();
  }

  void setDispatchDate(DateTime date) {
    state = state.copyWith(dispatchDate: date);
  }

  void setWeight(double weight) {
    state = state.copyWith(weight: weight);
    recalculateEstimate();
  }

  void setWeightUnit(String unit) {
    state = state.copyWith(weightUnit: unit);
    recalculateEstimate();
  }

  void setProduceType(String type) {
    state = state.copyWith(produceType: type);
    recalculateEstimate();
  }

  void setRequiresColdChain(bool coldChain) {
    state = state.copyWith(requiresColdChain: coldChain);
    recalculateEstimate();
  }

  Future<void> recalculateEstimate() async {
    state = state.copyWith(isEstimatingFare: true);
    try {
      final estimate = await _repository.estimateFare(
        pickup: state.pickupLocation,
        destination: state.destinationLocation,
        weightKg: state.weightInKg,
        produceType: state.produceType,
      );
      state = state.copyWith(
        fareEstimate: estimate,
        isEstimatingFare: false,
      );
    } catch (e) {
      state = state.copyWith(isEstimatingFare: false);
    }
  }

  Future<List<HaulerAgencyModel>> findHaulers() async {
    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final request = FindHaulersRequest(
        pickupLocation: state.pickupLocation,
        destinationLocation: state.destinationLocation,
        dispatchDate: state.dispatchDate,
        weightKg: state.weightInKg,
        produceType: state.produceType,
        requiresColdChain: state.requiresColdChain,
      );
      final list = await _repository.findHaulers(request);
      state = state.copyWith(isSearching: false);
      return list;
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Failed to find haulers: ${e.toString()}',
      );
      return [];
    }
  }
}

final bookingFormNotifierProvider =
    StateNotifierProvider<BookingFormNotifier, BookingFormState>((ref) {
  final repo = ref.watch(farmerDashboardRepositoryProvider);
  return BookingFormNotifier(repo);
});

// ==============================================================================
// Hauler Results State & Notifier
// ==============================================================================

class HaulerResultsState {
  final List<HaulerAgencyModel> haulers;
  final String sortBy; // 'price', 'rating', 'eta'
  final bool filterColdChainOnly;
  final bool isLoading;

  const HaulerResultsState({
    this.haulers = const [],
    this.sortBy = 'price',
    this.filterColdChainOnly = false,
    this.isLoading = false,
  });

  List<HaulerAgencyModel> get displayedHaulers {
    var filtered = List<HaulerAgencyModel>.from(haulers);
    if (filterColdChainOnly) {
      filtered = filtered.where((h) => h.coldChainSupported).toList();
    }
    switch (sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'eta':
        filtered.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
        break;
      case 'price':
      default:
        filtered.sort((a, b) => a.estimatedFare.compareTo(b.estimatedFare));
        break;
    }
    return filtered;
  }

  HaulerResultsState copyWith({
    List<HaulerAgencyModel>? haulers,
    String? sortBy,
    bool? filterColdChainOnly,
    bool? isLoading,
  }) {
    return HaulerResultsState(
      haulers: haulers ?? this.haulers,
      sortBy: sortBy ?? this.sortBy,
      filterColdChainOnly: filterColdChainOnly ?? this.filterColdChainOnly,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HaulerResultsNotifier extends StateNotifier<HaulerResultsState> {
  HaulerResultsNotifier() : super(const HaulerResultsState());

  void setHaulers(List<HaulerAgencyModel> list) {
    state = state.copyWith(haulers: list);
  }

  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }

  void toggleColdChainOnly(bool val) {
    state = state.copyWith(filterColdChainOnly: val);
  }
}

final haulerResultsNotifierProvider =
    StateNotifierProvider<HaulerResultsNotifier, HaulerResultsState>((ref) {
  return HaulerResultsNotifier();
});
