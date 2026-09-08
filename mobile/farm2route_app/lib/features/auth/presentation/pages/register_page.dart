import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../../shared/widgets/farm2route_logo.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'FARMER';
  bool _obscurePassword = true;

  final List<Map<String, dynamic>> _roles = [
    {
      'label': 'Farmer',
      'value': 'FARMER',
      'icon': Icons.agriculture_rounded,
      'desc': 'Ship fresh produce at fair rates',
    },
    {
      'label': 'Logistics Agency',
      'value': 'AGENCY',
      'icon': Icons.business_rounded,
      'desc': 'Manage truck fleets and drivers',
    },
    {
      'label': 'Driver',
      'value': 'DRIVER',
      'icon': Icons.local_shipping_rounded,
      'desc': 'Accept trips and complete PODs',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).register(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: Text('Create Account', style: AppTextStyles.headingSmall),
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
                    size: 68,
                    showWordmark: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join Farm2Route',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your account type to access specialized tools',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Role Selection Cards
                RadioGroup<String>(
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                  child: Column(
                    children: _roles.map((role) {
                      final isSelected = _selectedRole == role['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: AgrizelCard(
                          onTap: () => setState(
                              () => _selectedRole = role['value'] as String),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          color: isSelected
                              ? AppColors.primaryContainer
                              : Colors.white,
                          borderRadius: 18,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  role['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['label'] as String,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      role['desc'] as String,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: role['value'] as String,
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Kasun Perera',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondary),
                  ),
                  validator: InputValidators.validateName,
                ),
                const SizedBox(height: 14),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+94 77 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: InputValidators.validatePhone,
                ),
                const SizedBox(height: 14),

                // Email Address
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'name@farmexample.com',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Create Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: InputValidators.validatePassword,
                ),
                const SizedBox(height: 24),

                // Submit Button
                AgrizelPillButton(
                  text: 'Create Account & Verify OTP',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
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
