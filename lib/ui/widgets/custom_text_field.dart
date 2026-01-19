import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      style: Theme.of(context).textTheme.bodyLarge, // Use theme text style
      decoration: InputDecoration(
        labelText: widget.label,
        // Remove hardcoded labelStyle, let it inherit or use inputDecorationTheme
        // Remove filled/fillColor, let it inherit from inputDecorationTheme
        // Remove borders, let them inherit from inputDecorationTheme
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, // Use outlined for cleaner look
                  color: AppColors.textSecondary, // Use direct color without opacity
                ),
                onPressed: _toggleVisibility,
              )
            : null,
      ),
    );
  }
}
