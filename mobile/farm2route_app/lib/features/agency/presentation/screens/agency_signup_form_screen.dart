import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../../shared/widgets/farm2route_logo.dart';
import '../../data/models/agency_signup_request.dart';
import '../providers/agency_signup_provider.dart';

class AgencySignupFormScreen extends ConsumerStatefulWidget {
  const AgencySignupFormScreen({super.key});

  @override
  ConsumerState<AgencySignupFormScreen> createState() => _AgencySignupFormScreenState();
}

class _AgencySignupFormScreenState extends ConsumerState<AgencySignupFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _agencyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessRegNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();

  String? _selectedAgencyType;
  String? _selectedDistrict;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  static const List<Map<String, String>> _agencyTypes = [
    {
      'label': 'Individual Owner-Operator',
      'value': 'INDIVIDUAL',
    },
    {
      'label': 'Registered Company',
      'value': 'COMPANY',
    },
    {
      'label': 'Partnership',
      'value': 'PARTNERSHIP',
    },
  ];

  static const List<String> _sriLankaDistricts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  @override
  void initState() {
    super.initState();
    _agencyNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _businessRegNumberController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessRegNumberController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    super.dispose();
  }

  bool get _isBrnRequired =>
      _selectedAgencyType == 'COMPANY' || _selectedAgencyType == 'PARTNERSHIP';

  bool get _isFormFilled {
    return _agencyNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedAgencyType != null &&
        _selectedDistrict != null &&
        _addressController.text.trim().isNotEmpty &&
        _termsAccepted;
  }

  String? _validateAgencyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Agency name is required';
    }
    if (value.trim().length < 2) {
      return 'Agency name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(' ', '');
    final regex = RegExp(r'^(?:\+94|0)?([1-9][0-9]{8})$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid 9-digit mobile number (e.g. 771234567)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    return InputValidators.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateBrn(String? value) {
    if (_isBrnRequired) {
      if (value == null || value.trim().isEmpty) {
        return 'Business Registration Number is mandatory for ${_selectedAgencyType == "COMPANY" ? "companies" : "partnerships"}';
      }
      if (value.trim().length < 3) {
        return 'Business Registration Number must be at least 3 characters';
      }
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete office address';
    }
    return null;
  }

  String _formatPhoneNumber(String input) {
    final cleaned = input.trim().replaceAll(' ', '');
    final match = RegExp(r'^(?:\+94|0)?([1-9][0-9]{8})$').firstMatch(cleaned);
    if (match != null) {
      return '+94${match.group(1)}';
    }
    return cleaned.startsWith('+94') ? cleaned : '+94$cleaned';
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please accept the Terms & Conditions to proceed'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        return;
      }

      final brn = _businessRegNumberController.text.trim();
      final request = AgencySignupRequest(
        agencyName: _agencyNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _formatPhoneNumber(_phoneController.text),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        agencyType: _selectedAgencyType!,
        businessRegNumber: brn.isEmpty ? null : brn,
        district: _selectedDistrict!,
        address: _addressController.text.trim(),
        contactPersonName: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
      );

      final success = await ref.read(agencySignupNotifierProvider.notifier).signUp(request);
      if (success && mounted) {
        final signupState = ref.read(agencySignupNotifierProvider);
        final response = signupState.response;
        context.go(RouteNames.agencyVerify, extra: response);
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Terms & Conditions', style: AppTextStyles.headingSmall),
        content: SingleChildScrollView(
          child: Text(
            'By registering as a Logistics Agency on Farm2Route, you agree to comply with transport regulations, maintain active vehicle KYC credentials, adhere to scheduled agricultural cargo dispatch routes, and respect farmer delivery integrity.\n\nAll submitted agency profiles are reviewed by the platform administration before fleet deployment.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(agencySignupNotifierProvider);

    ref.listen(agencySignupNotifierProvider, (previous, next) {
      if (next.status == AgencySignupStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: Text('Agency Registration', style: AppTextStyles.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.landing);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Farm2RouteLogo(
                    size: 64,
                    showWordmark: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Register Your Fleet',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Step 1 of 3: Agency Details & Fleet Information',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 1. Agency Name
                TextFormField(
                  key: const Key('agency_name_field'),
                  controller: _agencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Agency Name *',
                    hintText: 'e.g. Lanka Logistics Express',
                    prefixIcon: Icon(Icons.business_rounded, color: AppColors.textSecondary),
                  ),
                  validator: _validateAgencyName,
                ),
                const SizedBox(height: 14),

                // 2. Email Address
                TextFormField(
                  key: const Key('agency_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'agency@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),

                // 3. Phone Number with +94 prefix
                TextFormField(
                  key: const Key('agency_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '771234567',
                    prefixText: '+94 ',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 14),

                // 4. Password
                TextFormField(
                  key: const Key('agency_password_field'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),

                // 5. Confirm Password
                TextFormField(
                  key: const Key('agency_confirm_password_field'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 14),

                // 6. Agency Type Dropdown
                DropdownButtonFormField<String>(
                  key: const Key('agency_type_dropdown'),
                  initialValue: _selectedAgencyType,
                  decoration: const InputDecoration(
                    labelText: 'Agency Type *',
                    prefixIcon: Icon(Icons.category_outlined, color: AppColors.textSecondary),
                  ),
                  items: _agencyTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']!, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedAgencyType = val);
                  },
                  validator: (val) =>
                      val == null ? 'Please select an agency type' : null,
                ),
                const SizedBox(height: 14),

                // 7. Business Registration Number (Mandatory for COMPANY / PARTNERSHIP)
                TextFormField(
                  key: const Key('agency_brn_field'),
                  controller: _businessRegNumberController,
                  decoration: InputDecoration(
                    labelText: _isBrnRequired
                        ? 'Business Registration Number (BRN) *'
                        : 'Business Registration Number (BRN) (Optional)',
                    hintText: 'e.g. PV-12345 or W-98765',
                    prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.textSecondary),
                    helperText: _isBrnRequired
                        ? 'Mandatory for registered companies & partnerships'
                        : 'Optional for individual owner-operators',
                  ),
                  validator: _validateBrn,
                ),
                const SizedBox(height: 14),

                // 8. District Dropdown
                DropdownButtonFormField<String>(
                  key: const Key('agency_district_dropdown'),
                  initialValue: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.textSecondary),
                  ),
                  items: _sriLankaDistricts.map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedDistrict = val);
                  },
                  validator: (val) =>
                      val == null ? 'Please select a district' : null,
                ),
                const SizedBox(height: 14),

                // 9. Office Address (Multiline)
                TextFormField(
                  key: const Key('agency_address_field'),
                  controller: _addressController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Office Address *',
                    hintText: 'e.g. 123 High Level Road, Colombo',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 14),

                // 10. Contact Person Name (Optional)
                TextFormField(
                  key: const Key('agency_contact_person_field'),
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person Name (Optional)',
                    hintText: 'e.g. Kamal Perera',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 18),

                // 11. Terms & Conditions Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        key: const Key('agency_terms_checkbox'),
                        value: _termsAccepted,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() => _termsAccepted = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                            ),
                            const TextSpan(text: ' and Privacy Policy of Farm2Route.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 12. Submit Button
                AgrizelPillButton(
                  key: const Key('agency_submit_button'),
                  text: 'Continue to Verification',
                  isLoading: signupState.status == AgencySignupStatus.loading,
                  onPressed: _isFormFilled ? _submit : null,
                ),
                const SizedBox(height: 20),

                // Switch to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.login),
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
