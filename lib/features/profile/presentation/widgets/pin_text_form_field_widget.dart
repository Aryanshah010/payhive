// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';

class PinTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final String? Function(String?)? validator;

  const PinTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.label,
    this.validator,
  });

  @override
  _PinTextFormFieldState createState() => _PinTextFormFieldState();
}

class _PinTextFormFieldState extends State<PinTextFormField> {
  bool _obscurePin = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MainTextFormField(
      controller: widget.controller,
      prefixIcon: Icons.lock_outline,
      hintText: widget.hintText,
      label: widget.label,
      keyboardType: TextInputType.number,
      obscureText: _obscurePin,
      validator: widget.validator,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePin ? Icons.visibility_off : Icons.visibility,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        onPressed: () => setState(() => _obscurePin = !_obscurePin),
      ),
    );
  }
}