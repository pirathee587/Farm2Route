import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/agency_repository.dart';
import '../../data/agency_profile_model.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>(
    (ref) => AgencyRepository(ref.watch(apiClientProvider)));

final agencyResourceProvider =
    FutureProvider.family<List<dynamic>, String>((ref, resource) async {
  return ref.watch(agencyRepositoryProvider).list(resource);
});

final agencyDashboardProvider = FutureProvider<dynamic>(
    (ref) => ref.watch(agencyRepositoryProvider).getDashboard());

final agencyProfileProvider = FutureProvider<AgencyProfileModel>((ref) async {
  final data = await ref.watch(agencyRepositoryProvider).getProfile();
  return AgencyProfileModel.fromJson(Map<String, dynamic>.from(data as Map));
});

final assignmentRecommendationProvider = FutureProvider.family<dynamic, String>(
    (ref, bookingId) => ref
        .watch(agencyRepositoryProvider)
        .getAssignmentRecommendation(bookingId));
