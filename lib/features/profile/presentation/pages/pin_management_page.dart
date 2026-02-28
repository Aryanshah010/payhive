import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/state/pin_state.dart';
import 'package:payhive/features/profile/presentation/view_model/pin_view_model.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/profile/presentation/widgets/pin_text_form_field_widget.dart';

class PinManagementPage extends ConsumerStatefulWidget {
  final bool hasPin;
  final bool isForced;
  final VoidCallback? onSuccess;

  const PinManagementPage({
    super.key,
    required this.hasPin,
    this.isForced = false,
    this.onSuccess,
  });

  @override
  ConsumerState<PinManagementPage> createState() => _PinManagementPageState();
}

class _PinManagementPageState extends ConsumerState<PinManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _pinValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your PIN';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
      return 'PIN must be exactly 4 digits.';
    }
    return null;
  }

  String? _confirmPinValidator(String? value) {
    final error = _pinValidator(value);
    if (error != null) return error;
    if (value != _newPinController.text) {
      return 'PINs do not match';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      await ref
          .read(pinViewModelProvider.notifier)
          .submitPin(
            newPin: _newPinController.text.trim(),
            oldPin: widget.hasPin ? _oldPinController.text.trim() : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double horizontalPadding = isTablet ? 48 : 16;
    final double verticalSpacing = isTablet ? 28 : 16;
    final double imageWidth = isTablet ? 500 : 250;
    final double titleFontSize = isTablet ? 32 : 20;

    final pinState = ref.watch(pinViewModelProvider);

    ref.listen<PinState>(pinViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == PinStatus.error && next.errorMessage != null) {
        SnackbarUtil.showError(context, next.errorMessage!);
      }

      if (next.status == PinStatus.success) {
        final message = widget.hasPin
            ? 'PIN updated successfully.'
            : 'PIN set successfully.';
        SnackbarUtil.showSuccess(context, message);
        ref.read(profileViewModelProvider.notifier).loadProfile();
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          AppRoutes.pop(context);
        }
      }
    });

    final title = widget.hasPin ? 'Update PIN' : 'Set PIN';
    final subtitle = widget.hasPin
        ? 'Enter your current PIN and choose a new one.'
        : 'Create a 4-digit PIN to secure your account.';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Image.asset('assets/images/payhive.png', width: imageWidth),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  color: colorScheme.onSurface,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: isTablet ? 24 : 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: isTablet ? 18 : 14,
                ),
              ),
              SizedBox(height: isTablet ? 60 : 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (widget.hasPin) ...[
                      if (widget.hasPin) ...[
                        PinTextFormField(
                          controller: _oldPinController,
                          hintText: 'Enter current PIN',
                          label: 'Current PIN',
                          validator: _pinValidator,
                        ),
                        SizedBox(height: verticalSpacing),
                      ],

                      PinTextFormField(
                        controller: _newPinController,
                        hintText: 'Enter new PIN',
                        label: 'New PIN',
                        validator: _pinValidator,
                      ),
                      SizedBox(height: verticalSpacing),

                      PinTextFormField(
                        controller: _confirmPinController,
                        hintText: 'Re-type new PIN',
                        label: 'Confirm PIN',
                        validator: _confirmPinValidator,
                      ),
                    ],
                    SizedBox(height: isTablet ? 20 : 12),
                    PrimaryButtonWidget(
                      onPressed: _handleSubmit,
                      isLoading: pinState.status == PinStatus.loading,
                      text: widget.hasPin ? 'Update PIN' : 'Set PIN',
                    ),
                    if (!widget.isForced) ...[
                      SizedBox(height: isTablet ? 26 : 16),
                      TextButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          AppRoutes.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: isTablet ? 60 : 30),
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
