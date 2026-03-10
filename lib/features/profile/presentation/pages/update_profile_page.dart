import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/state/update_profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/profile/presentation/view_model/update_profile_view_model.dart';

class UpdateProfilePage extends ConsumerStatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  ConsumerState<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends ConsumerState<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProfileViewModelProvider);
    final viewModel = ref.read(updateProfileViewModelProvider.notifier);

    if (_fullNameController.text != state.fullName) {
      _fullNameController.text = state.fullName;
    }
    if (_emailController.text != state.email) {
      _emailController.text = state.email;
    }
    if (_phoneController.text != state.phoneNumber) {
      _phoneController.text = state.phoneNumber;
    }

    ref.listen<UpdateProfileState>(updateProfileViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearMessages();
      }

      if (prev?.infoMessage != next.infoMessage &&
          next.infoMessage != null &&
          next.infoMessage!.isNotEmpty) {
        SnackbarUtil.showInfo(context, next.infoMessage!);
        viewModel.clearMessages();
      }

      if (prev?.status != UpdateProfileStatus.success &&
          next.status == UpdateProfileStatus.success) {
        SnackbarUtil.showSuccess(context, 'Profile updated successfully.');
        ref.read(profileViewModelProvider.notifier).refreshProfile();
        AppRoutes.pop(context);
      }
    });

    final isSubmitting = state.status == UpdateProfileStatus.submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.status == UpdateProfileStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      onChanged: viewModel.setFullName,
                      validator: (value) =>
                          _optionalValidator(value, ValidatorUtil.fullnameValidator),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: viewModel.setEmail,
                      validator: (value) =>
                          _optionalValidator(value, ValidatorUtil.emailValidator),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: false,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          _optionalValidator(value, ValidatorUtil.passwordValidator),
                      decoration: InputDecoration(
                        labelText: 'New Password (optional)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final password = _passwordController.text.trim();
                        if (password.isEmpty) return null;
                        return ValidatorUtil.confirmPasswordValidator(
                          value: value,
                          originalPassword: password,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _showConfirmPassword = !_showConfirmPassword,
                            );
                          },
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButtonWidget(
                      onPressed: () {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        viewModel.submit(
                          password: _passwordController.text,
                          confirmPassword: _confirmPasswordController.text,
                        );
                      },
                      isLoading: isSubmitting,
                      text: 'Update Profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _optionalValidator(
    String? value,
    String? Function(String? value) validator,
  ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validator(value);
  }
}
