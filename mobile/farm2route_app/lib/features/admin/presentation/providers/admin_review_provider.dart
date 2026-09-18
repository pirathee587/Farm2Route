import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin_review_model.dart';
import 'admin_provider.dart';

final adminReportedReviewsProvider =
    FutureProvider<List<AdminReviewModel>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getReportedReviews();
});

void refreshReportedReviews(WidgetRef ref) {
  ref.invalidate(adminReportedReviewsProvider);
}
