// ==============================================================================
// FarmerLandingScreen
// ==============================================================================
// ARCHITECTURE & CONTRIBUTOR NOTE:
// This is the dedicated welcoming landing screen for the Farmer user persona
// (modeled after modern ride-hailing/delivery welcome screens like Uber & PickMe).
//
// THIS IS NOT A DASHBOARD.
// Do NOT place freight centers, dispatch lists, live truck maps, order tables,
// or pricing widgets on this screen.
//
// Dashboard and operational UIs reside in their respective files:
//   - lib/features/farmer/presentation/pages/farmer_dashboard_page.dart (Farmer Hub)
//   - lib/features/agency/presentation/pages/agency_dashboard_page.dart (Agency Dispatch Hub)
//   - lib/features/admin/presentation/pages/admin_dashboard_page.dart   (Admin Console)
//   - lib/features/auth/presentation/pages/landing_page.dart           (Marketplace Demo)
//
// PURPOSE:
// 1. Greet the farmer with an inviting agricultural-logistics hero visual.
// 2. State the core farmer value proposition ("Get your harvest to market, faster.").
// 3. Primary CTA: "Get Started" -> enters the 4-step signup flow starting with
//    farmer_phone_entry_screen.dart (Phone -> OTP -> Farm Details).
// 4. Secondary CTA: "I already have an account — Log in" -> navigates to
//    farmer_login_screen.dart (Phone + OTP passwordless login).
// 5. Unobtrusive language selector (Tamil, Sinhala, English).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../../shared/widgets/farm2route_logo.dart';

class FarmerLandingScreen extends ConsumerWidget {
  const FarmerLandingScreen({super.key});

  void _showLanguageSelectorSheet(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(farmerLanguageProvider);
    final l10n = ref.read(farmerLocalizationsProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.selectLanguageTitle,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;
                return InkWell(
                  onTap: () {
                    ref.read(farmerLanguageProvider.notifier).setLanguage(lang);
                    Navigator.of(sheetContext).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          )
                        else
                          Text(
                            lang.code,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(farmerLocalizationsProvider);
    final currentLang = ref.watch(farmerLanguageProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final heroHeight = (screenHeight * 0.54).clamp(320.0, 500.0);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        top: false, // Allow hero section to stretch cleanly to status bar
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===============================================================
              // 1. TOP HERO SECTION (roughly 55% of screen height)
              // ===============================================================
              // Visually clean, full-width representation of farming + logistics.
              // Note: No text overlay on the illustration per requirements.
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Background gradient canvas
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE3F7EC), // Mint light tint
                              Color(0xFFCEF1DE), // Soft emerald transition
                              Color(0xFFBAEBD0), // Grounded harvest tint
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Decorative organic topography contours
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Center Agri-Logistics illustration placeholder.
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                              maxWidth: 360, maxHeight: 260),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColors.primaryContainer,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hero Eco-Truck & Harvest Pin Motif
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.agriculture_rounded,
                                      size: 40,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Connected route arrow
                                  Container(
                                    height: 3,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLight
                                          .withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      size: 40,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              // Aesthetic organic route pill indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.eco_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Farm to Market • Direct Route',
                                        style: AppTextStyles.tagText.copyWith(
                                          color: AppColors.primaryDark,
                                          fontSize: 12,
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
                  ],
                ),
              ),

              // ===============================================================
              // 2. CONTENT SECTION (below hero)
              // ===============================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(28.0, 24.0, 28.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App / Brand logo mark (small, top of content section)
                    const Center(
                      child: Farm2RouteLogo(
                        size: 38,
                        showWordmark: false,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Headline text (large, bold, brand font)
                    Text(
                      l10n.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtext / Tagline describing farmer value proposition
                    Text(
                      l10n.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // =========================================================
                    // 3. PRIMARY CTA BUTTON: "Get Started"
                    // =========================================================
                    // Navigates to the first step of the farmer signup flow
                    // (farmer_phone_entry_screen.dart).
                    AgrizelPillButton(
                      text: l10n.getStartedButton,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        context.push(RouteNames.farmerPhoneEntry);
                      },
                    ),
                    const SizedBox(height: 14),

                    // =========================================================
                    // 4. SECONDARY CTA BUTTON: "I already have an account — Log in"
                    // =========================================================
                    // Navigates to farmer_login_screen.dart (Phone + OTP form).
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push(RouteNames.farmerLogin);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          l10n.alreadyHaveAccount,
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Agency Registration Action
                    TextButton.icon(
                      onPressed: () {
                        context.push(RouteNames.agencySignupForm);
                      },
                      icon: const Icon(
                        Icons.business_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Logistics Agency? Register Fleet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // =========================================================
                    // 5. BOTTOM LANGUAGE SELECTOR
                    // =========================================================
                    // Small, unobtrusive button showing current language
                    // that opens a modal bottom sheet to switch locale.
                    InkWell(
                      onTap: () => _showLanguageSelectorSheet(context, ref),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language_rounded,
                              size: 16,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${currentLang.label} ▾',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
