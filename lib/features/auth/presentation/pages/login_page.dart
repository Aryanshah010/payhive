import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:payhive/features/auth/presentation/state/auth_state.dart';
import 'package:payhive/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:payhive/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:payhive/features/auth/presentation/pages/signup_page.dart';
import 'package:payhive/features/auth/presentation/pages/forgot_password_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authViewModelProvider.notifier)
          .login(
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
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

    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        SnackbarUtil.showError(context, next.errorMessage!);
      }

      if (next.status == AuthStatus.authenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        AppRoutes.pushReplacement(context, const DashboardScreen());
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
                "Welcome to Payhive",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  color: colorScheme.onSurface,
                  fontFamily: "Poppins",
                ),
              ),

              SizedBox(height: isTablet ? 80 : 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    MainTextFormField(
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_iphone_outlined,
                      controller: _phoneController,
                      hintText: "Enter your mobile number",
                      label: "Mobile Number",
                      validator: ValidatorUtil.phoneNumberValidator,
                    ),

                    SizedBox(height: verticalSpacing),

                    MainTextFormField(
                      prefixIcon: Icons.lock_outline,
                      controller: _passwordController,
                      hintText: "Enter your password",
                      label: "Password",
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

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          AppRoutes.push(context, const ForgotPasswordPage());
                        },
                        child: Text(
                          "Forget Password?",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 14,
                            fontWeight: FontWeight.w400,
                            decorationColor: AppColors.primary,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 20 : 10),

                    PrimaryButtonWidget(
                      onPressed: _handleLogin,
                      isLoading: authState.status == AuthStatus.loading,
                      text: "Login",
                    ),

                    SizedBox(height: isTablet ? 26 : 16),

                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isTablet ? 20 : 14,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(text: "Don’t have an account? "),
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(color: AppColors.primary),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                ref
                                    .read(authViewModelProvider.notifier)
                                    .clearStatus();
                                AppRoutes.pushReplacement(
                                  context,
                                  const SignupPage(),
                                );
                              },
                          ),
                        ],
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
