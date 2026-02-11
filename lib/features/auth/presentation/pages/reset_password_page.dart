import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/auth/presentation/pages/login_page.dart';
import 'package:payhive/features/auth/presentation/state/password_reset_state.dart';
import 'package:payhive/features/auth/presentation/view_model/password_reset_view_model.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _tokenValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter the reset token";
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(passwordResetViewModelProvider.notifier)
          .resetPassword(
            token: _tokenController.text.trim(),
            newPassword: _newPasswordController.text,
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

    final resetState = ref.watch(passwordResetViewModelProvider);

    ref.listen<PasswordResetState>(passwordResetViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.status == next.status) return;

      if (next.status == PasswordResetStatus.error && next.errorMessage != null) {
        SnackbarUtil.showError(context, next.errorMessage!);
      }

      if (next.status == PasswordResetStatus.resetSuccess) {
        SnackbarUtil.showSuccess(context, "Password reset successfully.");
        AppRoutes.pushReplacement(context, const LoginPage());
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Image.asset('assets/images/payhive.png', width: imageWidth),

              Text(
                "Reset Password",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  color: colorScheme.onSurface,
                  fontFamily: "Poppins",
                ),
              ),

              SizedBox(height: isTablet ? 24 : 12),

              Text(
                "Enter the reset token and your new password.",
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
                    MainTextFormField(
                      prefixIcon: Icons.key_outlined,
                      controller: _tokenController,
                      hintText: "Paste reset token",
                      label: "Reset Token",
                      validator: _tokenValidator,
                    ),

                    SizedBox(height: verticalSpacing),

                    MainTextFormField(
                      prefixIcon: Icons.lock_outline,
                      controller: _newPasswordController,
                      hintText: "Enter new password",
                      label: "New Password",
                      validator: ValidatorUtil.passwordValidator,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    SizedBox(height: verticalSpacing),

                    MainTextFormField(
                      prefixIcon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      hintText: "Re-type new password",
                      label: "Confirm Password",
                      validator: (value) {
                        return ValidatorUtil.confirmPasswordValidator(
                          originalPassword: _newPasswordController.text,
                          value: value,
                        );
                      },
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 20 : 12),

                    PrimaryButtonWidget(
                      onPressed: _handleResetPassword,
                      isLoading:
                          resetState.status == PasswordResetStatus.loading,
                      text: "Reset Password",
                    ),

                    SizedBox(height: isTablet ? 26 : 16),

                    TextButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        AppRoutes.pushReplacement(context, const LoginPage());
                      },
                      child: Text(
                        "Back to Login",
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

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
