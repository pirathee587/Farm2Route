import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/agency/data/models/agency_signup_request.dart';
import 'package:farm2route_app/features/agency/data/models/agency_verification_models.dart';
import 'package:farm2route_app/features/agency/domain/repositories/agency_repository.dart';
import 'package:farm2route_app/features/agency/presentation/providers/agency_signup_provider.dart';
import 'package:farm2route_app/features/agency/presentation/screens/agency_verify_screen.dart';

class MockAgencyVerifyRepo implements AgencyRepository {
  bool verifyPhoneCalled = false;
  String? lastOtp;
  bool resendPhoneCalled = false;
  bool resendEmailCalled = false;
  bool getStatusCalled = false;

  bool returnBothVerifiedOnPhone = false;

  @override
  Future<AgencyResponseModel> signUp(AgencySignupRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<AgencyStatusModel> verifyEmail(String agencyId, String emailToken) async {
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'agency@farm2route.lk',
      phoneNumber: '+94771234567',
      status: 'ACCOUNT_CREATED',
      emailVerified: true,
      phoneVerified: false,
    );
  }

  @override
  Future<AgencyStatusModel> verifyPhone(String agencyId, String otp) async {
    verifyPhoneCalled = true;
    lastOtp = otp;
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'agency@farm2route.lk',
      phoneNumber: '+94771234567',
      status: returnBothVerifiedOnPhone ? 'PENDING_VERIFICATION' : 'ACCOUNT_CREATED',
      emailVerified: returnBothVerifiedOnPhone,
      phoneVerified: true,
    );
  }

  @override
  Future<void> resendEmail(String agencyId) async {
    resendEmailCalled = true;
  }

  @override
  Future<void> resendPhoneOtp(String agencyId) async {
    resendPhoneCalled = true;
  }

  @override
  Future<AgencyStatusModel> getStatus(String agencyId) async {
    getStatusCalled = true;
    return AgencyStatusModel(
      agencyId: agencyId,
      email: 'agency@farm2route.lk',
      phoneNumber: '+94771234567',
      status: 'ACCOUNT_CREATED',
      emailVerified: false,
      phoneVerified: false,
    );
  }
}

Widget createVerifyWidget({
  required MockAgencyVerifyRepo repo,
  AgencyResponseModel? initialData,
}) {
  return ProviderScope(
    overrides: [
      agencyRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: AgencyVerifyScreen(agencyData: initialData),
    ),
  );
}

void main() {
  group('AgencyVerifyScreen Widget Tests', () {
    late MockAgencyVerifyRepo mockRepo;
    const testAgencyData = AgencyResponseModel(
      id: 'agency-uuid-12345',
      agencyName: 'Lanka Transporters',
      email: 'contact@lankatrans.lk',
      phoneNumber: '+94771234567',
      agencyType: 'COMPANY',
      district: 'Colombo',
      address: '100 Road, Colombo',
      status: 'ACCOUNT_CREATED',
      emailVerified: false,
      phoneVerified: false,
    );

    setUp(() {
      mockRepo = MockAgencyVerifyRepo();
    });

    testWidgets('renders dual verification cards and headers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createVerifyWidget(
        repo: mockRepo,
        initialData: testAgencyData,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Contact Details'), findsOneWidget);
      expect(find.text('Phone: Pending'), findsOneWidget);
      expect(find.text('Email: Pending'), findsOneWidget);
      expect(find.text('Mobile Number OTP'), findsOneWidget);
      expect(find.text('Email Verification Link'), findsOneWidget);
      expect(find.byKey(const Key('agency_otp_input')), findsOneWidget);
      expect(find.byKey(const Key('agency_verify_otp_button')), findsOneWidget);
      expect(find.byKey(const Key('agency_resend_email_button')), findsOneWidget);
      expect(find.byKey(const Key('agency_check_email_status_button')), findsOneWidget);
    });

    testWidgets('verifies phone OTP on button press',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createVerifyWidget(
        repo: mockRepo,
        initialData: testAgencyData,
      ));
      await tester.pumpAndSettle();

      // Enter 6-digit OTP
      final otpField = find.byKey(const Key('agency_otp_input'));
      await tester.enterText(otpField, '123456');
      await tester.pumpAndSettle();

      // Tap Verify Phone
      final verifyButton = find.byKey(const Key('agency_verify_otp_button'));
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(mockRepo.verifyPhoneCalled, isTrue);
      expect(mockRepo.lastOtp, equals('123456'));
      expect(find.text('Mobile phone successfully verified'), findsOneWidget);
    });

    testWidgets('triggers resend email and check status calls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createVerifyWidget(
        repo: mockRepo,
        initialData: testAgencyData,
      ));
      await tester.pumpAndSettle();

      // Tap Resend Email
      final resendEmailBtn = find.byKey(const Key('agency_resend_email_button'));
      await tester.tap(resendEmailBtn);
      await tester.pumpAndSettle();
      expect(mockRepo.resendEmailCalled, isTrue);

      // Tap Check Status
      final checkStatusBtn = find.byKey(const Key('agency_check_email_status_button'));
      await tester.tap(checkStatusBtn);
      await tester.pumpAndSettle();
      expect(mockRepo.getStatusCalled, isTrue);
    });
  });
}
