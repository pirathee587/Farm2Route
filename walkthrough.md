# Walkthrough: Public Landing Screen Cleanup

Updated the public landing screen (`PublicLandingScreen`) to streamline the unauthenticated user browsing experience:

1. **Removed Notification Bell Button**:
   - Removed the notification bell button (`Icons.notifications_none_rounded`) with the green badge from [LandingLocationRow](file:///c:/Users/Piratheepan/Desktop/Farm2Route/mobile/farm2route_app/lib/features/landing/presentation/widgets/landing_location_row.dart) since notifications are not applicable on the public without-login view.
   - Preserved the clean "Pickup near [Location] ▼" interactive district selector.

2. **Verification & Automated Tests**:
   - Updated [public_landing_screen_test.dart](file:///c:/Users/Piratheepan/Desktop/Farm2Route/mobile/farm2route_app/test/features/landing/public_landing_screen_test.dart) to assert `expect(find.byIcon(Icons.notifications_none_rounded), findsNothing)`.
   - `flutter test test/features/landing/public_landing_screen_test.dart` — **8 / 8 Passed**
   - `flutter test` — **40 / 40 Passed across all features**
   - `flutter analyze lib/features/landing/` — **No issues found!**
