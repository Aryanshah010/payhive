import 'package:flutter/material.dart';

class MainTextFormField extends StatelessWidget {
  const MainTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.label,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.obscureText=false ,
  });

  final TextEditingController controller;
  final String hintText;
  final String label;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),

        SizedBox(height: 4),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey)
                : null,
            suffixIcon: suffixIcon,
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 230, 230, 230),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 255, 230, 204),
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "field cannot be empty";
            }
            return null;
          },
        ),
      ],
    );
  }
}
