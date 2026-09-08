import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/review_notification_models.dart';
import 'agency_provider.dart';

final agencyReviewsProvider =
    FutureProvider<List<AgencyReviewModel>>((ref) async {
  final data = await ref.watch(agencyRepositoryProvider).getAgencyReviews();
  return data
      .map((item) =>
          AgencyReviewModel.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final driverReviewsProvider =
    FutureProvider.family<List<AgencyReviewModel>, String>(
        (ref, driverId) async {
  final data =
      await ref.watch(agencyRepositoryProvider).getDriverReviews(driverId);
  return data
      .map((item) =>
          AgencyReviewModel.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final agencyNotificationsProvider =
    FutureProvider<List<AgencyNotificationModel>>((ref) async {
  final data = await ref.watch(agencyRepositoryProvider).getNotifications();
  return data
      .map((item) => AgencyNotificationModel.fromJson(
          Map<String, dynamic>.from(item as Map)))
      .toList();
});

final agencyUnreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(agencyRepositoryProvider).getUnreadNotificationCount();
});
