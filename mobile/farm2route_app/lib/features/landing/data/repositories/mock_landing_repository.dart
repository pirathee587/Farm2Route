import 'package:flutter/material.dart';
import '../../domain/repositories/landing_repository.dart';
import '../models/agro_agency_model.dart';
import '../models/featured_promo_model.dart';
import '../models/transport_package_model.dart';

class MockLandingRepository implements LandingRepository {
  static const List<TransportPackageModel> _allPackages = [
    // Package 1 (Requested by User)
    TransportPackageModel(
      id: 'pkg-1',
      agencyName: 'Central Agro Hub',
      rating: 4.8,
      reviewCount: 120,
      pickupLocation: 'Dambulla',
      deliveryMarket: 'Manning Wholesale Market, Colombo',
      pricePerKg: 15.0,
      vehicleType: 'Bulk Cargo Truck',
      maxWeightKg: 5000,
      availableTrucks: 24,
      distanceKm: 12.0,
      status: 'ACTIVE',
      category: 'Bulk Cargo',
      hasOffer: true,
      offerLabel: '20% OFF',
    ),

    // Package 2 (Requested by User)
    TransportPackageModel(
      id: 'pkg-2',
      agencyName: 'Northern Agro Logistics',
      rating: 4.7,
      reviewCount: 95,
      pickupLocation: 'Jaffna',
      deliveryMarket: 'Colombo Wholesale Market',
      pricePerKg: 18.0,
      vehicleType: 'Harvest Transport Truck',
      maxWeightKg: 3000,
      availableTrucks: 8,
      distanceKm: 5.0,
      status: 'ACTIVE',
      category: 'Harvest Transport',
      hasOffer: true,
      offerLabel: 'LKR 150 OFF',
    ),

    // Package 3 (Requested by User)
    TransportPackageModel(
      id: 'pkg-3',
      agencyName: 'Green Farm Transport',
      rating: 4.9,
      reviewCount: 180,
      pickupLocation: 'Vavuniya',
      deliveryMarket: 'Kandy Market',
      pricePerKg: 14.0,
      vehicleType: 'Refrigerated Truck',
      maxWeightKg: 2000,
      availableTrucks: 12,
      distanceKm: 8.0,
      status: 'ACTIVE',
      category: 'Refrigerated',
      hasOffer: false,
    ),

    // Package 4: Express Haul
    TransportPackageModel(
      id: 'pkg-4',
      agencyName: 'Lanka Rapid Haulers',
      rating: 4.8,
      reviewCount: 88,
      pickupLocation: 'Kilinochchi',
      deliveryMarket: 'Dambulla DEC',
      pricePerKg: 19.0,
      vehicleType: 'Express Haul Van',
      maxWeightKg: 1500,
      availableTrucks: 6,
      distanceKm: 3.5,
      status: 'ACTIVE',
      category: 'Express Haul',
      hasOffer: true,
      offerLabel: 'FAST DISPATCH',
    ),

    // Package 5: Bulk Grain Cargo
    TransportPackageModel(
      id: 'pkg-5',
      agencyName: 'Rajarata Cargo Lines',
      rating: 4.6,
      reviewCount: 110,
      pickupLocation: 'Anuradhapura',
      deliveryMarket: 'Peliyagoda Central Market',
      pricePerKg: 13.5,
      vehicleType: 'Bulk Cargo Truck',
      maxWeightKg: 6500,
      availableTrucks: 15,
      distanceKm: 14.0,
      status: 'ACTIVE',
      category: 'Bulk Cargo',
      hasOffer: false,
    ),

    // Package 6: Wayamba Harvest
    TransportPackageModel(
      id: 'pkg-6',
      agencyName: 'Wayamba Harvest Movers',
      rating: 4.7,
      reviewCount: 75,
      pickupLocation: 'Kurunegala',
      deliveryMarket: 'Thotalanga Vegetable Terminal',
      pricePerKg: 16.0,
      vehicleType: 'Harvest Transport Truck',
      maxWeightKg: 4000,
      availableTrucks: 10,
      distanceKm: 9.2,
      status: 'ACTIVE',
      category: 'Harvest Transport',
      hasOffer: true,
      offerLabel: 'HARVEST SPECIAL',
    ),

    // Inactive Package (Must be excluded by filter)
    TransportPackageModel(
      id: 'pkg-inactive-7',
      agencyName: 'Deprecated Hauler Fleet',
      rating: 3.5,
      reviewCount: 10,
      pickupLocation: 'Colombo',
      deliveryMarket: 'Galle Harbor',
      pricePerKg: 25.0,
      vehicleType: 'Flatbed',
      maxWeightKg: 1000,
      availableTrucks: 0,
      distanceKm: 50.0,
      status: 'INACTIVE',
      category: 'Bulk Cargo',
    ),
  ];

  static const List<FeaturedPromoModel> _promos = [
    FeaturedPromoModel(
      id: 'promo-1',
      title: '20% OFF Your First Transport',
      ribbonBadge: '20% OFF',
      agencyName: 'Central Agro Hub',
      rating: 4.8,
      reviewsCount: 120,
      availabilityTag: '24 trucks available',
      bannerColor: Color(0xFF1B5E20), // Deep Forest Green
      icon: Icons.local_shipping_rounded,
      code: 'FIRST20',
    ),
    FeaturedPromoModel(
      id: 'promo-2',
      title: 'LKR 150 OFF Selected Trips',
      ribbonBadge: 'LKR 150 OFF',
      agencyName: 'Northern Agro Logistics',
      rating: 4.7,
      reviewsCount: 95,
      availabilityTag: '8 trucks available',
      bannerColor: Color(0xFF0D47A1), // Trust Blue
      icon: Icons.flash_on_rounded,
      code: 'TRIP150',
    ),
    FeaturedPromoModel(
      id: 'promo-3',
      title: 'Special Harvest Season Rates',
      ribbonBadge: 'HARVEST RATES',
      agencyName: 'Green Farm Transport',
      rating: 4.9,
      reviewsCount: 180,
      availabilityTag: '12 trucks available',
      bannerColor: Color(0xFFE65100), // Harvest Amber
      icon: Icons.eco_rounded,
      code: 'HARVEST24',
    ),
  ];

  static const List<AgroAgencyModel> _agencies = [
    AgroAgencyModel(
      id: 'ag-1',
      name: 'Central Agro Hub',
      rating: 4.8,
      reviewsCount: 120,
      availableTrucks: 24,
      district: 'Dambulla',
      icon: Icons.warehouse_rounded,
    ),
    AgroAgencyModel(
      id: 'ag-2',
      name: 'Northern Agro Logistics',
      rating: 4.7,
      reviewsCount: 95,
      availableTrucks: 8,
      district: 'Jaffna',
      icon: Icons.local_shipping_rounded,
    ),
    AgroAgencyModel(
      id: 'ag-3',
      name: 'Green Farm Transport',
      rating: 4.9,
      reviewsCount: 180,
      availableTrucks: 12,
      district: 'Vavuniya',
      icon: Icons.ac_unit_rounded,
    ),
    AgroAgencyModel(
      id: 'ag-4',
      name: 'Highland Cold Express',
      rating: 4.8,
      reviewsCount: 145,
      availableTrucks: 16,
      district: 'Kandy',
      icon: Icons.airport_shuttle_rounded,
    ),
    AgroAgencyModel(
      id: 'ag-5',
      name: 'Rajarata Cargo Lines',
      rating: 4.6,
      reviewsCount: 110,
      availableTrucks: 15,
      district: 'Anuradhapura',
      icon: Icons.fire_truck_rounded,
    ),
  ];

  @override
  Future<List<TransportPackageModel>> getActivePackages({
    String? category,
    String? district,
    String? produceType,
    double? maxPrice,
    bool? offersOnly,
  }) async {
    // Only return ACTIVE packages
    var list = _allPackages.where((pkg) => pkg.status == 'ACTIVE').toList();

    if (category != null && category != 'All' && category.isNotEmpty) {
      list = list.where((pkg) => pkg.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (offersOnly == true) {
      list = list.where((pkg) => pkg.hasOffer).toList();
    }

    if (maxPrice != null && maxPrice > 0) {
      list = list.where((pkg) => pkg.pricePerKg <= maxPrice).toList();
    }

    return list;
  }

  @override
  Future<List<FeaturedPromoModel>> getFeaturedPromos() async {
    return _promos;
  }

  @override
  Future<List<AgroAgencyModel>> getTopAgencies() async {
    return _agencies;
  }
}
