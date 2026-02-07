import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/auth/presentation/pages/login_page.dart';
import 'package:payhive/features/auth/presentation/pages/reset_password_page.dart';
import 'package:payhive/features/auth/presentation/state/password_reset_state.dart';
import 'package:payhive/features/auth/presentation/view_model/password_reset_view_model.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(passwordResetViewModelProvider.notifier)
          .requestPasswordReset(email: _emailController.text.trim());
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

      if (next.status == PasswordResetStatus.emailSent) {
        SnackbarUtil.showSuccess(
          context,
          "Reset link sent. Please check your email.",
        );
        AppRoutes.push(context, ResetPasswordPage(token: next.token));
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
                "Forgot Password",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  color: colorScheme.onSurface,
                  fontFamily: "Poppins",
                ),
              ),

              SizedBox(height: isTablet ? 24 : 12),

              Text(
                "Enter your email to receive a password reset link.",
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
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      hintText: "Enter your email",
                      label: "Email",
                      validator: ValidatorUtil.emailValidator,
                    ),

                    SizedBox(height: verticalSpacing),

                    PrimaryButtonWidget(
                      onPressed: _handleRequestReset,
                      isLoading:
                          resetState.status == PasswordResetStatus.loading,
                      text: "Send Reset Link",
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
