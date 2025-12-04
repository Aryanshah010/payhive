import 'package:flutter/material.dart';
import 'package:payhive/screens/signin_screen.dart';
import 'package:payhive/utils/validator_util.dart';
import 'package:payhive/widgets/main_text_form_field.dart';
import 'package:payhive/widgets/primary_button_widget.dart';
import 'package:flutter/gestures.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    final double horizontalPadding = isTablet ? 48 : 16;
    final double verticalSpacing = isTablet ? 28 : 20;
    final double imageHeight = isTablet ? 260 : 190;
    final double imageWidth = isTablet ? 300 : 228;
    final double titleFontSize = isTablet ? 32 : 24;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: isTablet ? 60 : 30),

              Image.asset(
                'assets/images/payhive.png',
                height: imageHeight,
                width: imageWidth,
                color: Colors.orange,
              ),

              SizedBox(height: verticalSpacing),

              Text(
                "Welcome to Payhive",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
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
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forget Password?",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.orange,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 40 : 30),

                    PrimaryButtonWidget(
                      onPressed: () {
                        if (_formKey.currentState?.validate() == true) {}
                      },
                      text: "Login",
                    ),

                    SizedBox(height: isTablet ? 40 : 36),

                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Color(0xFF7A7A7A),
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: "Don’t have an account? "),
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: Colors.orange,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SigninScreen(),
                                  ),
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
