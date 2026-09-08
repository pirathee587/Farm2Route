import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farm2route_app/app/router/route_names.dart';
import 'package:farm2route_app/features/agency/data/models/agency_signup_request.dart';
import 'package:farm2route_app/features/agency/data/models/agency_verification_models.dart';
import 'package:farm2route_app/features/agency/domain/repositories/agency_repository.dart';
import 'package:farm2route_app/features/agency/presentation/providers/agency_signup_provider.dart';
import 'package:farm2route_app/features/agency/presentation/screens/agency_signup_form_screen.dart';

class FakeAgencyRepository implements AgencyRepository {
  AgencySignupRequest? lastSignupRequest;

  @override
  Future<AgencyResponseModel> signUp(AgencySignupRequest request) async {
    lastSignupRequest = request;
    return AgencyResponseModel(
      id: 'agency-test-123',
      agencyName: request.agencyName,
      email: request.email,
      phoneNumber: request.phoneNumber,
      agencyType: request.agencyType,
      businessRegNumber: request.businessRegNumber,
      district: request.district,
      address: request.address,
      contactPersonName: request.contactPersonName,
      status: 'ACCOUNT_CREATED',
      emailVerified: false,
      phoneVerified: false,
    );
  }

  @override
  Future<AgencyStatusModel> verifyEmail(String agencyId, String emailToken) async {
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'test@example.com',
      phoneNumber: '+94771234567',
      status: 'ACCOUNT_CREATED',
      emailVerified: true,
      phoneVerified: false,
    );
  }

  @override
  Future<AgencyStatusModel> verifyPhone(String agencyId, String otp) async {
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'test@example.com',
      phoneNumber: '+94771234567',
      status: 'PENDING_VERIFICATION',
      emailVerified: true,
      phoneVerified: true,
    );
  }

  @override
  Future<void> resendEmail(String agencyId) async {}

  @override
  Future<void> resendPhoneOtp(String agencyId) async {}

  @override
  Future<AgencyStatusModel> getStatus(String agencyId) async {
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'test@example.com',
      phoneNumber: '+94771234567',
      status: 'ACCOUNT_CREATED',
      emailVerified: false,
      phoneVerified: false,
    );
  }
}

Widget createWidgetWithRepo(FakeAgencyRepository repo) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => const AgencySignupFormScreen(),
      ),
      GoRoute(
        path: RouteNames.agencyVerify,
        builder: (context, state) => const Scaffold(body: Text('Verify Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      agencyRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('AgencySignupFormScreen Widget Tests', () {
    late FakeAgencyRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAgencyRepository();
    });

    testWidgets('renders all fields including BRN and terms checkbox',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetWithRepo(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Register Your Fleet'), findsOneWidget);
      expect(find.byKey(const Key('agency_name_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_email_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_password_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('agency_brn_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_district_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('agency_address_field')), findsOneWidget);
      expect(find.byKey(const Key('agency_terms_checkbox')), findsOneWidget);
    });

    testWidgets('requires BRN when Registered Company is selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetWithRepo(fakeRepo));
      await tester.pumpAndSettle();

      // Enter all fields except BRN
      await tester.enterText(
          find.byKey(const Key('agency_name_field')), 'Ceylon Freight Ltd');
      await tester.enterText(
          find.byKey(const Key('agency_email_field')), 'fleet@ceylon.lk');
      await tester.enterText(
          find.byKey(const Key('agency_phone_field')), '771234567');
      await tester.enterText(
          find.byKey(const Key('agency_password_field')), 'SecurePass123!');
      await tester.enterText(
          find.byKey(const Key('agency_confirm_password_field')), 'SecurePass123!');

      // Select Company
      final typeDropdown = find.byKey(const Key('agency_type_dropdown'));
      await tester.ensureVisible(typeDropdown);
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Company').last);
      await tester.pumpAndSettle();

      // Select District
      final districtDropdown = find.byKey(const Key('agency_district_dropdown'));
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo').last);
      await tester.pumpAndSettle();

      // Enter address
      final addressField = find.byKey(const Key('agency_address_field'));
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '100 Port Access Road, Colombo');

      // Check Terms
      final terms = find.byKey(const Key('agency_terms_checkbox'));
      await tester.ensureVisible(terms);
      await tester.tap(terms);
      await tester.pumpAndSettle();

      // Tap Submit
      final submitButton = find.byKey(const Key('agency_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect BRN validation error for company
      expect(
        find.text('Business Registration Number is mandatory for companies'),
        findsOneWidget,
      );
    });

    testWidgets('allows Individual Owner-Operator signup without BRN',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetWithRepo(fakeRepo));
      await tester.pumpAndSettle();

      // Enter all fields
      await tester.enterText(
          find.byKey(const Key('agency_name_field')), 'Saman Solo Trucker');
      await tester.enterText(
          find.byKey(const Key('agency_email_field')), 'saman@trucker.lk');
      await tester.enterText(
          find.byKey(const Key('agency_phone_field')), '771234567');
      await tester.enterText(
          find.byKey(const Key('agency_password_field')), 'SecurePass123!');
      await tester.enterText(
          find.byKey(const Key('agency_confirm_password_field')), 'SecurePass123!');

      // Select Individual
      final typeDropdown = find.byKey(const Key('agency_type_dropdown'));
      await tester.ensureVisible(typeDropdown);
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Individual Owner-Operator').last);
      await tester.pumpAndSettle();

      // Select District
      final districtDropdown = find.byKey(const Key('agency_district_dropdown'));
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Galle').last);
      await tester.pumpAndSettle();

      // Enter address
      final addressField = find.byKey(const Key('agency_address_field'));
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '50 Main Street, Galle');

      // Check Terms
      final terms = find.byKey(const Key('agency_terms_checkbox'));
      await tester.ensureVisible(terms);
      await tester.tap(terms);
      await tester.pumpAndSettle();

      // Tap Submit
      final submitButton = find.byKey(const Key('agency_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should not show BRN error and repo should have received request with null BRN
      expect(find.text('Business Registration Number is mandatory for companies'), findsNothing);
      expect(fakeRepo.lastSignupRequest, isNotNull);
      expect(fakeRepo.lastSignupRequest!.agencyType, equals('INDIVIDUAL'));
      expect(fakeRepo.lastSignupRequest!.businessRegNumber, isNull);
    });
  });
}
