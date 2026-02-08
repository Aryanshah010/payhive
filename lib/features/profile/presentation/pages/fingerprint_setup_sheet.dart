import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/services/biometric/biometric_service.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/domain/usecases/verify_pin_usecase.dart';

class FingerprintSetupSheet extends ConsumerStatefulWidget {
  const FingerprintSetupSheet({super.key});

  @override
  ConsumerState<FingerprintSetupSheet> createState() =>
      _FingerprintSetupSheetState();
}

class _FingerprintSetupSheetState
    extends ConsumerState<FingerprintSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricAvailable = true;
  bool _biometricEnrolled = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final service = ref.read(biometricServiceProvider);
    final available = await service.isBiometricAvailable();
    final enrolled = available ? await service.hasEnrolledBiometrics() : false;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnrolled = enrolled;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleEnableFingerprint() async {
    if (!_biometricAvailable) {
      setState(() {
        _errorMessage = 'Biometric authentication is not available.';
      });
      return;
    }

    if (!_biometricEnrolled) {
      setState(() {
        _errorMessage = 'No biometrics enrolled. Enable Face ID/Touch ID first.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final verifyUsecase = ref.read(verifyPinUsecaseProvider);
    final result = await verifyUsecase(
      VerifyPinParams(pin: _pinController.text.trim()),
    );

    final verified = result.fold(
      (failure) {
        setState(() => _errorMessage = failure.message);
        return false;
      },
      (success) => success,
    );

    if (!verified) {
      setState(() => _isLoading = false);
      return;
    }

    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate(
      reason: 'Confirm your fingerprint to enable login.',
    );

    if (!authenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fingerprint authentication cancelled.';
      });
      return;
    }

    final sessionService = ref.read(userSessionServiceProvider);
    final userId = sessionService.getUserId();
    final fullName = sessionService.getUserFullName();
    final phoneNumber = sessionService.getUserPhoneNumber();

    if (userId == null || fullName == null || phoneNumber == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session missing. Please login again.';
      });
      return;
    }

    final storage = ref.read(biometricStorageServiceProvider);
    await storage.enable(
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;
    SnackbarUtil.showSuccess(context, 'Fingerprint enabled successfully.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Enable Fingerprint',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 4-digit PIN to continue.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  MainTextFormField(
                    controller: _pinController,
                    prefixIcon: Icons.lock_outline,
                    hintText: 'Enter PIN',
                    label: 'PIN',
                    keyboardType: TextInputType.number,
                    obscureText: _obscurePin,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your PIN';
                      }
                      if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
                        return 'PIN must be exactly 4 digits.';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: () => setState(
                        () => _obscurePin = !_obscurePin,
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  PrimaryButtonWidget(
                    onPressed: _isLoading ? () {} : _handleEnableFingerprint,
                    isLoading: _isLoading,
                    text: 'Enable Fingerprint',
                  ),
                  const SizedBox(height: 12),
                  if (!_biometricAvailable)
                    Text(
                      'Biometrics not available on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (_biometricAvailable && !_biometricEnrolled)
                    Text(
                      'No biometrics enrolled on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
