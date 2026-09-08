import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/agency_repository.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>(
    (ref) => AgencyRepository(ref.watch(apiClientProvider)));

final agencyResourceProvider =
    FutureProvider.family<List<dynamic>, String>((ref, resource) async {
  return ref.watch(agencyRepositoryProvider).list(resource);
});

final agencyDashboardProvider = FutureProvider<dynamic>(
    (ref) => ref.watch(agencyRepositoryProvider).getDashboard());

final assignmentRecommendationProvider = FutureProvider.family<dynamic, String>(
    (ref, bookingId) => ref
        .watch(agencyRepositoryProvider)
        .getAssignmentRecommendation(bookingId));
