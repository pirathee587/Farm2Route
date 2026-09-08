import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../agency/presentation/screens/agency_signup_form_screen.dart';
import '../../../farmer/presentation/screens/farmer_phone_entry_screen.dart';

/// Unified Modern Sign Up Screen for Farm2Route
/// Allows users to register as either an Agency Fleet or a Farmer with dedicated, full-featured flows.
class RegisterPage extends ConsumerStatefulWidget {
  final String initialRole;

  const RegisterPage({
    super.key,
    this.initialRole = 'AGENCY',
  });

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.landing);
            }
          },
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Segmented Role Tab Switcher
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildRoleTab(
                  role: 'AGENCY',
                  title: '🏢 Logistics Agency',
                  subtitle: 'Fleet & Business',
                ),
                _buildRoleTab(
                  role: 'FARMER',
                  title: '🌾 Farmer',
                  subtitle: 'Phone & OTP',
                ),
              ],
            ),
          ),

          // Active Form View
          Expanded(
            child: _selectedRole == 'AGENCY'
                ? const AgencySignupFormScreen()
                : const FarmerPhoneEntryScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab({
    required String role,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
