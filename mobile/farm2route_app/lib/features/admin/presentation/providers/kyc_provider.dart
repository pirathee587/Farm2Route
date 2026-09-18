import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/kyc_summary_model.dart';
import 'admin_provider.dart';

final pendingAgencyKycProvider =
    FutureProvider<List<AgencyKycSummaryModel>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getPendingAgencyKyc();
});

final pendingDriverKycProvider =
    FutureProvider<List<DriverKycSummaryModel>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getPendingDriverKyc();
});

final pendingVehicleKycProvider =
    FutureProvider<List<VehicleKycSummaryModel>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getPendingVehicleKyc();
});

void refreshAllKycProviders(WidgetRef ref) {
  ref.invalidate(pendingAgencyKycProvider);
  ref.invalidate(pendingDriverKycProvider);
  ref.invalidate(pendingVehicleKycProvider);
  ref.invalidate(adminStatsProvider);
}

void refreshAllKycProvidersRef(Ref ref) {
  ref.invalidate(pendingAgencyKycProvider);
  ref.invalidate(pendingDriverKycProvider);
  ref.invalidate(pendingVehicleKycProvider);
  ref.invalidate(adminStatsProvider);
}
