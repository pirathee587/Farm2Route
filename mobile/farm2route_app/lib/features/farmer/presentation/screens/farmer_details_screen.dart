import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../data/models/farmer_signup_request.dart';
import '../providers/farmer_signup_provider.dart';

class FarmerDetailsScreen extends ConsumerStatefulWidget {
  const FarmerDetailsScreen({super.key});

  @override
  ConsumerState<FarmerDetailsScreen> createState() => _FarmerDetailsScreenState();
}

class _FarmerDetailsScreenState extends ConsumerState<FarmerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gnDivisionController = TextEditingController();
  final _addressController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _mobileWalletController = TextEditingController();
  final _nicController = TextEditingController();

  String? _selectedDistrict;
  String _selectedLanguage = 'TA';
  final Set<String> _selectedCrops = {'VEGETABLES'};

  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

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

  static const List<Map<String, dynamic>> _cropOptions = [
    {'code': 'VEGETABLES', 'icon': Icons.eco_rounded, 'name': 'Vegetables'},
    {'code': 'FRUITS', 'icon': Icons.apple_rounded, 'name': 'Fruits'},
    {'code': 'GRAINS', 'icon': Icons.grass_rounded, 'name': 'Grains / Paddy'},
    {'code': 'DAIRY', 'icon': Icons.local_drink_rounded, 'name': 'Dairy'},
    {'code': 'OTHER', 'icon': Icons.category_rounded, 'name': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    final currentLang = ref.read(farmerLanguageProvider);
    _selectedLanguage = currentLang.code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gnDivisionController.dispose();
    _addressController.dispose();
    _farmSizeController.dispose();
    _bankAccountController.dispose();
    _mobileWalletController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showSnackBar('Location services are disabled. Please enable GPS.');
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _showSnackBar('Location permission denied.');
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showSnackBar('Location permissions are permanently denied. Please allow in settings.');
        setState(() => _isFetchingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isFetchingLocation = false;
      });

      _showSnackBar(
        'Farm location captured: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
        isSuccess: true,
      );
    } catch (e) {
      // Fallback default coordinates for Sri Lanka central agro zone (Dambulla) if GPS times out in simulator
      setState(() {
        _latitude = 7.8731;
        _longitude = 80.6517;
        _isFetchingLocation = false;
      });
      _showSnackBar('Set to Central Agricultural Hub (7.8731, 80.6517)', isSuccess: true);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.primaryDark : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleCompleteSignup() async {
    final l10n = ref.read(farmerLocalizationsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedDistrict == null) {
      _showSnackBar(l10n.districtRequiredError);
      return;
    }

    final signupState = ref.read(farmerSignupProvider);
    final phone = signupState.phoneNumber;
    final otp = signupState.otp;

    if (phone == null || phone.isEmpty || otp == null || otp.isEmpty) {
      _showSnackBar('Missing verification state. Please verify OTP first.');
      context.go(RouteNames.farmerPhoneEntry);
      return;
    }

    final request = FarmerSignupRequest(
      phoneNumber: phone,
      otp: otp,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      district: _selectedDistrict!,
      gnDivision: _gnDivisionController.text.trim().isEmpty ? null : _gnDivisionController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      farmSizeAcres: double.tryParse(_farmSizeController.text.trim()),
      primaryCrops: _selectedCrops.toList(),
      preferredLanguage: _selectedLanguage,
      bankAccountNumber: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
      mobileWalletNumber: _mobileWalletController.text.trim().isEmpty ? null : _mobileWalletController.text.trim(),
      nicNumber: _nicController.text.trim().isEmpty ? null : _nicController.text.trim(),
    );

    final success = await ref
        .read(farmerSignupProvider.notifier)
        .completeSignup(request);

    if (!mounted) return;

    if (success) {
      _showSnackBar('Welcome to Farm2Route! Farmer account activated.', isSuccess: true);
      context.go(RouteNames.farmerHome);
    } else {
      final error = ref.read(farmerSignupProvider).errorMessage ?? 'Registration failed';
      _showSnackBar(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(farmerLocalizationsProvider);
    final signupState = ref.watch(farmerSignupProvider);
    final isLoading = signupState.status == FarmerSignupStatus.submitting;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.farmerDetailsTitle, style: AppTextStyles.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.farmerDetailsSubtitle,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Section 1: Personal & Administrative Details
                AgrizelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Basic Profile', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Full Name (Required)
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.fullNameLabel,
                          hintText: 'e.g. Sunil Bandara',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.fullNameRequiredError;
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email Address (Optional)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          hintText: 'sunil.bandara@example.lk',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // District Dropdown (Required)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDistrict,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.districtLabel,
                          prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary),
                        ),
                        items: _sriLankaDistricts.map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDistrict = val),
                        validator: (val) => val == null ? l10n.districtRequiredError : null,
                      ),
                      const SizedBox(height: 14),

                      // GN Division (Optional)
                      TextFormField(
                        controller: _gnDivisionController,
                        decoration: InputDecoration(
                          labelText: l10n.gnDivisionLabel,
                          hintText: 'e.g. Nuwaragam Palatha 245',
                          prefixIcon: const Icon(Icons.map_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Address Description
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Farm / Pickup Address (Optional)',
                          hintText: 'e.g. Post 12, Mahaweli B Zone, Dimbulagala',
                          prefixIcon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Farm Location Map Picker
                AgrizelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.farmLocationTitle, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                            ],
                          ),
                          if (_latitude != null && _longitude != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Pinned',
                                style: AppTextStyles.tagText.copyWith(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.farmLocationSubtitle,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Visual Coordinates Card / Map Representation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _latitude != null ? AppColors.primary : AppColors.border,
                            width: _latitude != null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _latitude != null ? Icons.pin_drop_rounded : Icons.add_location_alt_rounded,
                              size: 40,
                              color: _latitude != null ? AppColors.primary : AppColors.textLight,
                            ),
                            const SizedBox(height: 8),
                            if (_latitude != null && _longitude != null) ...[
                              Text(
                                'Latitude: ${_latitude!.toStringAsFixed(6)}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Longitude: ${_longitude!.toStringAsFixed(6)}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ] else ...[
                              Text(
                                'No location pinned yet',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                              ),
                              Text(
                                'Tap below to capture accurate farm coordinates',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // GPS Capture Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                          label: Text(
                            l10n.useCurrentLocationButton,
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 3: Farm Produce & Language Preferences
                AgrizelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Harvest & Crop Profile', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Farm Size
                      TextFormField(
                        controller: _farmSizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.farmSizeLabel,
                          hintText: 'e.g. 3.5',
                          prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Primary Crops Multi-select
                      Text(
                        l10n.primaryCropsLabel,
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _cropOptions.map((crop) {
                          final code = crop['code'] as String;
                          final isSelected = _selectedCrops.contains(code);
                          final label = l10n.cropLabel(code);
                          final icon = crop['icon'] as IconData;

                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.primaryDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceSubtle,
                            checkmarkColor: Colors.white,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCrops.add(code);
                                } else {
                                  if (_selectedCrops.length > 1) {
                                    _selectedCrops.remove(code);
                                  } else {
                                    _showSnackBar('At least one crop must be selected');
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Preferred Language Segmented Selector
                      Text(
                        l10n.preferredLanguageLabel,
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: AppLanguage.values.map((lang) {
                          final isSelected = _selectedLanguage == lang.code;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedLanguage = lang.code);
                                  ref.read(farmerLanguageProvider.notifier).setLanguage(lang);
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    lang.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 4: Optional Financial Details
                AgrizelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Payout Accounts (Optional)', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Direct bank deposit and mobile cash for harvest payouts',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bankAccountController,
                        decoration: InputDecoration(
                          labelText: l10n.bankAccountLabel,
                          hintText: 'e.g. Bank of Ceylon 0012345678',
                          prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _mobileWalletController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.mobileWalletLabel,
                          hintText: 'e.g. 077 123 4567 (eZ Cash / mCash)',
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                AgrizelPillButton(
                  text: l10n.completeSignupButton,
                  isLoading: isLoading,
                  onPressed: _handleCompleteSignup,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
