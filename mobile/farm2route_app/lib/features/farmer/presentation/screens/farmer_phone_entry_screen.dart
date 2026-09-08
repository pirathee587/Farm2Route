import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../../shared/widgets/farm2route_logo.dart';
import '../providers/farmer_signup_provider.dart';

class FarmerPhoneEntryScreen extends ConsumerStatefulWidget {
  const FarmerPhoneEntryScreen({super.key});

  @override
  ConsumerState<FarmerPhoneEntryScreen> createState() => _FarmerPhoneEntryScreenState();
}

class _FarmerPhoneEntryScreenState extends ConsumerState<FarmerPhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _cleanPhoneNumber(String input) {
    String clean = input.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.startsWith('+94')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('94')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  Future<void> _handleSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawPhone = _phoneController.text.trim();
    final cleanPhone = _cleanPhoneNumber(rawPhone);
    final fullPhoneNumber = '+94$cleanPhone';

    final success = await ref
        .read(farmerSignupProvider.notifier)
        .requestOtp(fullPhoneNumber);

    if (!mounted) return;

    if (success) {
      context.push(RouteNames.farmerOtpVerify);
    } else {
      final error = ref.read(farmerSignupProvider).errorMessage ?? 'Failed to send OTP';
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

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(farmerLocalizationsProvider);
    final currentLang = ref.watch(farmerLanguageProvider);
    final signupState = ref.watch(farmerSignupProvider);
    final isLoading = signupState.status == FarmerSignupStatus.requestingOtp;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.register);
            }
          },
        ),
        actions: [
          // Language Switcher Dropdown
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: currentLang,
                icon: const Icon(Icons.language_rounded, size: 18, color: AppColors.primaryDark),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                onChanged: (newLang) {
                  if (newLang != null) {
                    ref.read(farmerLanguageProvider.notifier).setLanguage(newLang);
                  }
                },
                items: AppLanguage.values.map((lang) {
                  return DropdownMenuItem<AppLanguage>(
                    value: lang,
                    child: Text(lang.label),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Farm2Route Brand Logo
                const Center(
                  child: Farm2RouteLogo(size: 64, showWordmark: false),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                Text(
                  l10n.farmerSignupTitle,
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.phoneEntrySubtitle,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Phone Input Card
                AgrizelCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mobileNumberLabel,
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 12),

                      // Input with +94 Prefix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  const Text('🇱🇰', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+94',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppTextStyles.bodyLarge.copyWith(
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: '77 123 4567',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.phoneRequiredError;
                                }
                                final clean = _cleanPhoneNumber(value);
                                if (clean.length != 9 || !clean.startsWith('7')) {
                                  return l10n.phoneInvalidError;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Instant, passwordless SMS verification',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Send OTP Button
                AgrizelPillButton(
                  text: l10n.sendOtpButton,
                  isLoading: isLoading,
                  onPressed: _phoneController.text.trim().isEmpty ? null : _handleSendOtp,
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 20),

                // Switch to standard login
                TextButton(
                  onPressed: () => context.push(RouteNames.login),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
