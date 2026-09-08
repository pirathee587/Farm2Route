import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../data/models/agency_response_model.dart';
import '../providers/agency_verify_provider.dart';

class AgencyVerifyScreen extends ConsumerStatefulWidget {
  final AgencyResponseModel? agencyData;

  const AgencyVerifyScreen({
    super.key,
    this.agencyData,
  });

  @override
  ConsumerState<AgencyVerifyScreen> createState() => _AgencyVerifyScreenState();
}

class _AgencyVerifyScreenState extends ConsumerState<AgencyVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.agencyData != null) {
        ref.read(agencyVerifyNotifierProvider.notifier).init(
              agencyId: widget.agencyData!.id,
              email: widget.agencyData!.email,
              phoneNumber: widget.agencyData!.phoneNumber,
              emailVerified: widget.agencyData!.emailVerified,
              phoneVerified: widget.agencyData!.phoneVerified,
              status: widget.agencyData!.status,
            );
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit code'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final success = await ref
        .read(agencyVerifyNotifierProvider.notifier)
        .verifyPhone(otp);

    if (success) {
      _otpController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(agencyVerifyNotifierProvider);

    ref.listen(agencyVerifyNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else if (next.infoMessage != null &&
          next.infoMessage != previous?.infoMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.infoMessage!),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }

      if (next.isAllVerified && (previous == null || !previous.isAllVerified)) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            // ignore: use_build_context_synchronously
            context.go(RouteNames.agencyPendingReview);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: Text('Account Verification', style: AppTextStyles.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.agencySignup);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Text(
                'Step 2 of 3: Dual Verification',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Verify Your Contact Details',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Both your mobile number and email must be verified to submit your agency application for admin approval.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Overall status pill summary
              Row(
                children: [
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Phone',
                      isVerified: verifyState.phoneVerified,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Email',
                      isVerified: verifyState.emailVerified,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // CARD 1: Mobile Phone Verification
              AgrizelCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: verifyState.phoneVerified
                                ? AppColors.primaryContainer
                                : AppColors.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            verifyState.phoneVerified
                                ? Icons.phone_android_rounded
                                : Icons.phone_outlined,
                            color: verifyState.phoneVerified
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile Number OTP',
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                verifyState.phoneNumber.isNotEmpty
                                    ? verifyState.phoneNumber
                                    : 'Registered phone',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(verifyState.phoneVerified),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (verifyState.phoneVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mobile phone successfully verified',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Enter the 6-digit code sent to your phone number:',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('agency_otp_input'),
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          letterSpacing: 8.0,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••••',
                          hintStyle: AppTextStyles.headingMedium.copyWith(
                            letterSpacing: 8.0,
                            color: AppColors.textLight,
                          ),
                          filled: true,
                          fillColor: AppColors.canvasCream,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AgrizelPillButton(
                              key: const Key('agency_verify_otp_button'),
                              text: 'Verify Phone',
                              isLoading: verifyState.isSubmittingOtp,
                              onPressed: _onVerifyOtp,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          key: const Key('agency_resend_otp_button'),
                          onPressed: (verifyState.resendCooldownSeconds == 0 &&
                                  !verifyState.isResendingPhone)
                              ? () => ref
                                  .read(agencyVerifyNotifierProvider.notifier)
                                  .resendPhoneOtp()
                              : null,
                          child: verifyState.isResendingPhone
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                )
                              : Text(
                                  verifyState.resendCooldownSeconds > 0
                                      ? 'Resend SMS in ${verifyState.resendCooldownSeconds}s'
                                      : 'Resend SMS Code',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: verifyState.resendCooldownSeconds > 0
                                        ? AppColors.textLight
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // CARD 2: Email Verification
              AgrizelCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: verifyState.emailVerified
                                ? AppColors.primaryContainer
                                : AppColors.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            verifyState.emailVerified
                                ? Icons.mark_email_read_rounded
                                : Icons.mail_outline_rounded,
                            color: verifyState.emailVerified
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Verification Link',
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                verifyState.email.isNotEmpty
                                    ? verifyState.email
                                    : 'Registered email',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(verifyState.emailVerified),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (verifyState.emailVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Email address successfully verified',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'We sent a verification link to your email. Click the link in your email to verify, then tap "Check Status" below.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('agency_resend_email_button'),
                              onPressed: verifyState.isResendingEmail
                                  ? null
                                  : () => ref
                                      .read(agencyVerifyNotifierProvider.notifier)
                                      .resendEmail(),
                              icon: verifyState.isResendingEmail
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Resend Email'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AgrizelPillButton(
                              key: const Key('agency_check_email_status_button'),
                              text: 'Check Status',
                              isLoading: verifyState.isCheckingStatus,
                              onPressed: () => ref
                                  .read(agencyVerifyNotifierProvider.notifier)
                                  .checkStatus(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue CTA button (active when both verified or fallback button)
              if (verifyState.isAllVerified)
                AgrizelPillButton(
                  key: const Key('agency_proceed_to_review_button'),
                  text: 'Proceed to Application Review',
                  onPressed: () => context.go(RouteNames.agencyPendingReview),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.primaryContainer.withValues(alpha: 0.6)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 18,
            color: isVerified ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${isVerified ? "Verified" : "Pending"}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isVerified ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isVerified) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFE65100)),
          const SizedBox(width: 4),
          Text(
            'Pending',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFFE65100),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
