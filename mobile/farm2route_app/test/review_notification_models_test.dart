import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/agency/data/review_notification_models.dart';

void main() {
  test('parses the agency review response DTO', () {
    final review = AgencyReviewModel.fromJson({
      'id': 'review-1',
      'bookingId': 'booking-1',
      'bookingNumber': 'F2R-001',
      'driverId': null,
      'driverName': null,
      'agencyRating': 5,
      'agencyComment': 'Good service',
      'driverRating': 4,
      'driverComment': 'Careful driver',
      'agencyResponse': null,
      'agencyRespondedAt': null,
      'moderationStatus': 'APPROVED',
      'createdAt': '2026-09-08T10:00:00Z',
      'updatedAt': null,
    });

    expect(review.agencyRating, 5);
    expect(review.bookingNumber, 'F2R-001');
    expect(review.driverId, isNull);
    expect(review.responseRequest('Thanks'), {'response': 'Thanks'});
  });

  test('parses notification read state and nullable references', () {
    final notification = AgencyNotificationModel.fromJson({
      'id': 'notification-1',
      'userId': 'user-1',
      'title': 'New review received',
      'message': 'A farmer submitted a review.',
      'notificationType': 'SYSTEM',
      'referenceType': 'REVIEW',
      'referenceId': 'review-1',
      'read': false,
      'readAt': null,
      'createdAt': '2026-09-08T10:00:00Z',
    });

    expect(notification.notificationType, 'SYSTEM');
    expect(notification.read, isFalse);
    expect(notification.referenceId, 'review-1');
    expect(notification.readAt, isNull);
  });
}
