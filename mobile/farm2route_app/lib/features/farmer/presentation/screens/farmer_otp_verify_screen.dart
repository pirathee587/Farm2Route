import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../providers/farmer_signup_provider.dart';

class FarmerOtpVerifyScreen extends ConsumerStatefulWidget {
  const FarmerOtpVerifyScreen({super.key});

  @override
  ConsumerState<FarmerOtpVerifyScreen> createState() => _FarmerOtpVerifyScreenState();
}

class _FarmerOtpVerifyScreenState extends ConsumerState<FarmerOtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(_onDigitChanged);
    }
  }

  void _onDigitChanged() {
    setState(() {});
  }

  void _startCooldownTimer() {
    setState(() => _secondsRemaining = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    final phone = ref.read(farmerSignupProvider).phoneNumber;
    if (phone == null || phone.isEmpty) return;

    final success =
        await ref.read(farmerSignupProvider.notifier).requestOtp(phone);

    if (!mounted) return;

    if (success) {
      _startCooldownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New verification code sent to $phone'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else {
      final error = ref.read(farmerSignupProvider).errorMessage ?? 'Failed to resend OTP';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _handleVerify() {
    final l10n = ref.read(farmerLocalizationsProvider);
    final otp = _otpCode;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.otpRequiredError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final held = ref.read(farmerSignupProvider.notifier).holdOtp(otp);
    if (held) {
      // Proceed to Step 3: Farmer Details Form (backend creates record upon verify+submit)
      context.push(RouteNames.farmerDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(farmerLocalizationsProvider);
    final signupState = ref.watch(farmerSignupProvider);
    final phoneNumber = signupState.phoneNumber ?? '+94 77 XXX XXXX';

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),

              Text(
                l10n.verifyPhoneTitle,
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                '${l10n.otpSubtitle}\n$phoneNumber',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // 6-digit OTP Input Box Card
              AgrizelCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 54,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primaryDark,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: AppColors.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Resend Timer Row
                    if (_secondsRemaining > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.resendInText} ${_secondsRemaining}s',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: _handleResend,
                        icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                        label: Text(
                          l10n.resendOtpButton,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Verify & Continue Button
              AgrizelPillButton(
                text: l10n.verifyAndContinueButton,
                onPressed: _otpCode.length == 6 ? _handleVerify : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
