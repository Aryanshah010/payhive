import 'package:flutter/material.dart';
import 'package:payhive/theme/colors.dart';

class MainTextFormField extends StatelessWidget {
  const MainTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.label,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final String label;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isTablet = w >= 600;

    final double labelFont = isTablet ? 26 : 16;
    final double hintFont = isTablet ? 22 : 14;
    final double iconSize = isTablet ? 28 : 20;
    final double errorFont = isTablet ? 18 : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: labelFont, fontWeight: FontWeight.w500),
        ),

        SizedBox(height: isTablet ? 8 : 2),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          style: TextStyle(fontSize: hintFont),
          decoration: InputDecoration(
            errorStyle: TextStyle(fontSize: errorFont),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.greyText, size: iconSize)
                : null,
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: TextStyle(fontSize: hintFont, color:  AppColors.greyText),
          ),
        ),
      ],
    );
  }
}
