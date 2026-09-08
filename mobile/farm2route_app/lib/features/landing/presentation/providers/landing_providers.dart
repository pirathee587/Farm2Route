import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/agro_agency_model.dart';
import '../../data/models/featured_promo_model.dart';
import '../../data/models/transport_package_model.dart';
import '../../data/repositories/mock_landing_repository.dart';
import '../../domain/repositories/landing_repository.dart';

// Repository Provider
final landingRepositoryProvider = Provider<LandingRepository>((ref) {
  return MockLandingRepository();
});

// Location / District State
class LocationState {
  final String district;
  final String fullDisplay;
  final bool isGpsDetected;
  final bool isLoading;

  const LocationState({
    this.district = 'Jaffna',
    this.fullDisplay = 'Jaffna, Sri Lanka',
    this.isGpsDetected = false,
    this.isLoading = false,
  });

  LocationState copyWith({
    String? district,
    String? fullDisplay,
    bool? isGpsDetected,
    bool? isLoading,
  }) {
    return LocationState(
      district: district ?? this.district,
      fullDisplay: fullDisplay ?? this.fullDisplay,
      isGpsDetected: isGpsDetected ?? this.isGpsDetected,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  void setDistrict(String district) {
    state = state.copyWith(
      district: district,
      fullDisplay: '$district, Sri Lanka',
      isGpsDetected: false,
      isLoading: false,
    );
  }

  Future<void> detectGpsLocation() async {
    state = state.copyWith(isLoading: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fallback without failing
        state = state.copyWith(isLoading: false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Graceful fallback to default
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Map coordinates to closest major transport district in Sri Lanka
      final detectedDistrict = _mapCoordsToDistrict(position.latitude, position.longitude);
      state = state.copyWith(
        district: detectedDistrict,
        fullDisplay: '$detectedDistrict, Sri Lanka',
        isGpsDetected: true,
        isLoading: false,
      );
    } catch (_) {
      // Graceful fallback: maintain current district
      state = state.copyWith(isLoading: false);
    }
  }

  String _mapCoordsToDistrict(double lat, double lng) {
    // Basic bounding boxes for Sri Lankan agricultural districts
    if (lat > 9.4) return 'Jaffna';
    if (lat > 9.0) return 'Kilinochchi';
    if (lat > 8.5) return 'Vavuniya';
    if (lat > 8.0 && lng < 80.8) return 'Anuradhapura';
    if (lat > 7.7 && lng > 80.5) return 'Dambulla';
    if (lat > 7.3 && lng < 80.5) return 'Kurunegala';
    if (lat > 7.1 && lng > 80.5) return 'Kandy';
    return 'Colombo';
  }
}

final landingLocationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

// Category State: "All", "Express Haul", "Harvest Transport", "Bulk Cargo", "Refrigerated"
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Filter Pills State
enum SortOption { none, priceLowToHigh, ratingHighToLow, nearestDistance }

class FilterPillsState {
  final bool offersOnly;
  final SortOption sortOption;

  const FilterPillsState({
    this.offersOnly = false,
    this.sortOption = SortOption.none,
  });

  FilterPillsState copyWith({
    bool? offersOnly,
    SortOption? sortOption,
  }) {
    return FilterPillsState(
      offersOnly: offersOnly ?? this.offersOnly,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class FilterPillsNotifier extends StateNotifier<FilterPillsState> {
  FilterPillsNotifier() : super(const FilterPillsState());

  void toggleOffers() {
    state = state.copyWith(offersOnly: !state.offersOnly);
  }

  void setOffersOnly(bool value) {
    state = state.copyWith(offersOnly: value);
  }

  void togglePriceSort() {
    state = state.copyWith(
      sortOption: state.sortOption == SortOption.priceLowToHigh
          ? SortOption.none
          : SortOption.priceLowToHigh,
    );
  }

  void toggleRatingSort() {
    state = state.copyWith(
      sortOption: state.sortOption == SortOption.ratingHighToLow
          ? SortOption.none
          : SortOption.ratingHighToLow,
    );
  }

  void toggleNearestSort() {
    state = state.copyWith(
      sortOption: state.sortOption == SortOption.nearestDistance
          ? SortOption.none
          : SortOption.nearestDistance,
    );
  }

  void reset() {
    state = const FilterPillsState();
  }
}

final filterPillsProvider =
    StateNotifierProvider<FilterPillsNotifier, FilterPillsState>((ref) {
  return FilterPillsNotifier();
});

// Search Card Criteria State
class SearchCriteriaState {
  final bool isExpanded;
  final String pickupLocation;
  final String deliveryMarket;
  final double? cargoWeightKg;
  final String produceType;
  final String searchQuery;

  const SearchCriteriaState({
    this.isExpanded = false,
    this.pickupLocation = '',
    this.deliveryMarket = '',
    this.cargoWeightKg,
    this.produceType = '',
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      pickupLocation.isNotEmpty ||
      deliveryMarket.isNotEmpty ||
      cargoWeightKg != null ||
      produceType.isNotEmpty ||
      searchQuery.isNotEmpty;

  SearchCriteriaState copyWith({
    bool? isExpanded,
    String? pickupLocation,
    String? deliveryMarket,
    double? cargoWeightKg,
    String? produceType,
    String? searchQuery,
  }) {
    return SearchCriteriaState(
      isExpanded: isExpanded ?? this.isExpanded,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryMarket: deliveryMarket ?? this.deliveryMarket,
      cargoWeightKg: cargoWeightKg ?? this.cargoWeightKg,
      produceType: produceType ?? this.produceType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SearchCriteriaNotifier extends StateNotifier<SearchCriteriaState> {
  SearchCriteriaNotifier() : super(const SearchCriteriaState());

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
  }

  void updateQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCriteria({
    String? pickupLocation,
    String? deliveryMarket,
    double? cargoWeightKg,
    String? produceType,
  }) {
    state = state.copyWith(
      pickupLocation: pickupLocation,
      deliveryMarket: deliveryMarket,
      cargoWeightKg: cargoWeightKg,
      produceType: produceType,
      isExpanded: false, // collapse on find transport
    );
  }

  void reset() {
    state = const SearchCriteriaState();
  }
}

final searchCriteriaProvider =
    StateNotifierProvider<SearchCriteriaNotifier, SearchCriteriaState>((ref) {
  return SearchCriteriaNotifier();
});

// Async Promos Provider
final featuredPromosProvider = FutureProvider<List<FeaturedPromoModel>>((ref) {
  final repo = ref.watch(landingRepositoryProvider);
  return repo.getFeaturedPromos();
});

// Async Top Agencies Provider
final topAgenciesProvider = FutureProvider<List<AgroAgencyModel>>((ref) {
  final repo = ref.watch(landingRepositoryProvider);
  return repo.getTopAgencies();
});

// Filtered Packages Provider (Combines all filters and sort options)
final filteredPackagesProvider = FutureProvider<List<TransportPackageModel>>((ref) async {
  final repo = ref.watch(landingRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final filters = ref.watch(filterPillsProvider);
  final search = ref.watch(searchCriteriaProvider);

  final packages = await repo.getActivePackages(
    category: category == 'All' ? null : category,
    offersOnly: filters.offersOnly ? true : null,
  );

  var list = List<TransportPackageModel>.from(packages);

  // Apply search query / criteria filter
  if (search.searchQuery.trim().isNotEmpty) {
    final q = search.searchQuery.trim().toLowerCase();
    list = list.where((pkg) {
      return pkg.agencyName.toLowerCase().contains(q) ||
          pkg.pickupLocation.toLowerCase().contains(q) ||
          pkg.deliveryMarket.toLowerCase().contains(q) ||
          pkg.vehicleType.toLowerCase().contains(q) ||
          pkg.category.toLowerCase().contains(q);
    }).toList();
  }

  if (search.pickupLocation.isNotEmpty) {
    list = list
        .where((pkg) =>
            pkg.pickupLocation.toLowerCase().contains(search.pickupLocation.toLowerCase()))
        .toList();
  }

  if (search.deliveryMarket.isNotEmpty) {
    list = list
        .where((pkg) =>
            pkg.deliveryMarket.toLowerCase().contains(search.deliveryMarket.toLowerCase()))
        .toList();
  }

  if (search.cargoWeightKg != null && search.cargoWeightKg! > 0) {
    list = list.where((pkg) => pkg.maxWeightKg >= search.cargoWeightKg!).toList();
  }

  // Apply sorting
  switch (filters.sortOption) {
    case SortOption.priceLowToHigh:
      list.sort((a, b) => a.pricePerKg.compareTo(b.pricePerKg));
      break;
    case SortOption.ratingHighToLow:
      list.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case SortOption.nearestDistance:
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      break;
    case SortOption.none:
      break;
  }

  return list;
});
