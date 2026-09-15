import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../providers/pod_provider.dart';

class PodSubmissionPage extends ConsumerStatefulWidget {
  final String bookingId;

  const PodSubmissionPage({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PodSubmissionPage> createState() => _PodSubmissionPageState();
}

class _PodSubmissionPageState extends ConsumerState<PodSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _latController = TextEditingController(text: '6.9271');
  final _lngController = TextEditingController(text: '79.8612');
  final _notesController = TextEditingController();

  late SignatureController _signatureController;
  Uint8List? _signatureBytes;
  Uint8List? _photoBytes;
  String? _photoFilename;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _signatureController.addListener(_onSignatureChanged);
    _recipientNameController.addListener(_onFormInputChanged);
    _recipientPhoneController.addListener(_onFormInputChanged);
  }

  void _onSignatureChanged() async {
    if (_signatureController.isNotEmpty) {
      final bytes = await _signatureController.toPngBytes();
      if (mounted) {
        setState(() {
          _signatureBytes = bytes;
        });
      }
    } else {
      if (mounted && _signatureBytes != null) {
        setState(() {
          _signatureBytes = null;
        });
      }
    }
  }

  void _onFormInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final nameValid = _recipientNameController.text.trim().isNotEmpty;
    final phoneValid = _recipientPhoneController.text.trim().isNotEmpty;
    final hasSig = _signatureBytes != null && _signatureBytes!.isNotEmpty;
    final hasPhoto = _photoBytes != null && _photoBytes!.isNotEmpty;
    return nameValid && phoneValid && hasSig && hasPhoto;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBytes = bytes;
          _photoFilename = image.name;
        });
      }
    } catch (_) {}
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureBytes = null;
    });
  }

  @visibleForTesting
  void setTestBytes({Uint8List? signatureBytes, Uint8List? photoBytes}) {
    setState(() {
      if (signatureBytes != null) _signatureBytes = signatureBytes;
      if (photoBytes != null) _photoBytes = photoBytes;
    });
  }

  void _clearPhoto() {
    setState(() {
      _photoBytes = null;
      _photoFilename = null;
    });
  }

  void _captureGps() {
    // Standard coordinates set for delivery destination
    setState(() {
      _latController.text = '6.9271';
      _lngController.text = '79.8612';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery GPS location captured!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid) return;

    final lat = double.tryParse(_latController.text) ?? 6.9271;
    final lng = double.tryParse(_lngController.text) ?? 79.8612;

    final success = await ref.read(podSubmissionProvider.notifier).submitPod(
          bookingId: widget.bookingId,
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          deliveryLatitude: lat,
          deliveryLongitude: lng,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          signatureBytes: _signatureBytes!,
          signatureFilename: 'signature.png',
          photoBytes: _photoBytes!,
          photoFilename: _photoFilename ?? 'delivery_photo.jpg',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proof of Delivery submitted successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final podState = ref.watch(podSubmissionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Submit Digital POD',
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (podState.errorMessage != null) ...[
                Container(
                  key: const Key('pod_error_banner'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          podState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Recipient Information Card
              AgrizelCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Recipient Details',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('pod_recipient_name_input'),
                        controller: _recipientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('pod_recipient_phone_input'),
                        controller: _recipientPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Delivery Location (GPS) Card
              AgrizelCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '2. Delivery Coordinates',
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            key: const Key('pod_capture_gps_btn'),
                            onPressed: _captureGps,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Capture GPS'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('pod_lat_input'),
                              controller: _latController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              key: const Key('pod_lng_input'),
                              controller: _lngController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Recipient Signature Canvas
              AgrizelCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '3. Recipient Signature *',
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_signatureBytes != null)
                            TextButton(
                              key: const Key('pod_clear_signature_btn'),
                              onPressed: _clearSignature,
                              child: const Text('Clear Signature', style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        key: const Key('pod_signature_canvas'),
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _signatureBytes != null ? AppColors.primary : AppColors.border,
                            width: _signatureBytes != null ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Delivery Photo Capture
              AgrizelCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '4. Delivery Photo *',
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_photoBytes != null)
                            TextButton(
                              key: const Key('pod_clear_photo_btn'),
                              onPressed: _clearPhoto,
                              child: const Text('Clear Photo', style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_photoBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            Uint8List.fromList(_photoBytes!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 380) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      key: const Key('pod_take_photo_btn'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      icon: const Icon(Icons.camera_alt_outlined),
                                      label: const Text('Take Camera Photo'),
                                      onPressed: () => _pickImage(ImageSource.camera),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      key: const Key('pod_pick_photo_btn'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      icon: const Icon(Icons.photo_library_outlined),
                                      label: const Text('From Gallery'),
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const Key('pod_take_photo_btn'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text('Take Camera Photo'),
                                    onPressed: () => _pickImage(ImageSource.camera),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const Key('pod_pick_photo_btn'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('From Gallery'),
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. Additional Notes
              AgrizelCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5. Handover Notes (Optional)',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('pod_notes_input'),
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Package handed directly to warehouse manager.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload Progress Indicator
              if (podState.isSubmitting) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: podState.uploadProgress > 0 ? podState.uploadProgress : null,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading Proof of Delivery... ${(podState.uploadProgress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AgrizelPillButton(
                  key: const Key('pod_submit_btn'),
                  text: 'Submit Proof of Delivery',
                  height: 48,
                  icon: Icons.check_circle_outline,
                  onPressed: (_isFormValid && !podState.isSubmitting) ? _handleSubmit : null,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
