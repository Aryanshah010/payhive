import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:payhive/features/auth/presentation/pages/login_page.dart';
import 'package:payhive/features/auth/presentation/state/auth_state.dart';
import 'package:payhive/features/auth/presentation/view_model/auth_view_model.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _createPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _createPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .register(
            fullName: _fullnameController.text,
            phoneNumber: _phoneController.text,
            email: _emailController.text,
            password: _createPasswordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        SnackbarUtil.showError(context, next.errorMessage!);
      }

      if (next.status == AuthStatus.registered) {
        FocusManager.instance.primaryFocus?.unfocus();

        SnackbarUtil.showSuccess(context, 'Registration successful!');

        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(authViewModelProvider.notifier).clearStatus();

          if (mounted) {
            // ignore: use_build_context_synchronously
            AppRoutes.pushReplacement(context, const LoginPage());
          }
        });
      }
    });
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 600;

          final double horizontalPadding = isTablet ? 48 : 16;
          final double verticalSpacing = isTablet ? 28 : 16;
          final double imageWidth = isTablet ? 500 : 250;
          final double titleFontSize = isTablet ? 32 : 18;

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/payhive.png',
                        width: imageWidth,
                      ),
                    ),
                    SizedBox(height: isTablet ? 50 : 20),

                    Text(
                      "Create Your Payhive Account",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: titleFontSize,
                        color: colorScheme.onSurface,
                        fontFamily: "Poppins",
                      ),
                    ),

                    SizedBox(height: isTablet ? 50 : 30),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          MainTextFormField(
                            controller: _fullnameController,
                            prefixIcon: Icons.person_2_outlined,
                            hintText: "Enter your Full Name",
                            label: "Full Name",
                            validator: (value) =>
                                ValidatorUtil.fullnameValidator(value),
                          ),

                          SizedBox(height: verticalSpacing),

                          MainTextFormField(
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            controller: _emailController,
                            hintText: "Enter your email",
                            label: "Email",
                            validator: ValidatorUtil.emailValidator,
                          ),

                          SizedBox(height: verticalSpacing),

                          MainTextFormField(
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_iphone_outlined,
                            controller: _phoneController,
                            hintText: "Enter your phone number",
                            label: "Mobile Number",
                            validator: ValidatorUtil.phoneNumberValidator,
                          ),

                          SizedBox(height: verticalSpacing),

                          MainTextFormField(
                            prefixIcon: Icons.lock_outline,
                            controller: _createPasswordController,
                            hintText: "Enter a password",
                            label: "Create Password",
                            validator: (value) =>
                                ValidatorUtil.passwordValidator(value),
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
                            hintText: "Re-type the password",
                            label: "Confirm Password",
                            validator: (value) {
                              return ValidatorUtil.confirmPasswordValidator(
                                originalPassword:
                                    _createPasswordController.text,
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

                          SizedBox(height: isTablet ? 60 : 30),

                          PrimaryButtonWidget(
                            onPressed: _handleSignUp,
                            text: "Sign Up",
                            isLoading: authState.status == AuthStatus.loading,
                          ),

                          SizedBox(height: isTablet ? 36 : 16),

                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: isTablet ? 20 : 14,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(color: AppColors.primary),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      ref
                                          .read(authViewModelProvider.notifier)
                                          .clearStatus();
                                      AppRoutes.pushReplacement(
                                        context,
                                        const LoginPage(),
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
        },
      ),
    );
  }
}
