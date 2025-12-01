import 'package:flutter/material.dart';
import 'package:payhive/widgets/main_text_form_field.dart';
import 'package:payhive/widgets/primary_button_widget.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    height: 190,
                    width: 228,
                    'assets/images/payhive.png',
                    color: Colors.orange,
                  ),
                ),
                Text(
                  "Welcome to Payhive",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),

                SizedBox(height: 125),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MainTextFormField(
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_iphone_outlined,
                        controller: _phoneController,
                        hintText: "Enter your phone number",
                        label: "Mobile Number",
                      ),

                      SizedBox(height: 20),

                      MainTextFormField(
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        hintText: "Enter your password",
                        label: "Password",
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            color: Colors.grey,
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forget Password?",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Color.fromARGB(255, 255, 107, 0),
                              color: Color.fromARGB(255, 255, 107, 0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 36),

                      PrimaryButtonWidget(onPressed: () {
                         if (_formKey.currentState?.validate() == true) {print(_phoneController.text);}
                      }, text: "Login"),
                      SizedBox(height: 36),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Color.fromARGB(255, 122, 122, 122),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          children: <TextSpan>[
                            TextSpan(text: "Don’t have an account?\u00A0"),

                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 107, 0),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
