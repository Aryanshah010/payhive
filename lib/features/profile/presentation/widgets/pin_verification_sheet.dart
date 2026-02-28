import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/domain/usecases/verify_pin_usecase.dart';
import 'package:payhive/features/profile/presentation/widgets/pin_text_form_field_widget.dart';

/// Bottom‑sheet that asks the user to enter/verify their 4‑digit PIN.
class PinVerificationSheet extends ConsumerStatefulWidget {
  const PinVerificationSheet({super.key});

  @override
  ConsumerState<PinVerificationSheet> createState() =>
      _PinVerificationSheetState();
}

class _PinVerificationSheetState extends ConsumerState<PinVerificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(verifyPinUsecaseProvider)(
      VerifyPinParams(pin: _pinController.text.trim()),
    );

    if (!mounted) return;

    result.fold((failure) {
      setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      });
    }, (_) => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                  'Enter PIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your 4-digit PIN to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 16),
                PinTextFormField(
                  controller: _pinController,
                  hintText: 'Enter PIN',
                  label: 'PIN',
                  validator: (value) {
                    final cleaned = value?.trim() ?? '';
                    if (cleaned.isEmpty) {
                      return 'Please enter your PIN';
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
                      return 'PIN must be exactly 4 digits.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                  onPressed: _isLoading ? () {} : _handleVerify,
                  isLoading: _isLoading,
                  text: 'Verify PIN',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
