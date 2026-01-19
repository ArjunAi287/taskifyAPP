import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  void _toggleObscure() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine suffix icon: usage specific takes precedence, otherwise if it's a password field, show toggle
    Widget? activeSuffixIcon = widget.suffixIcon;
    if (widget.obscureText && activeSuffixIcon == null) {
       activeSuffixIcon = IconButton(
         icon: Icon(
           _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
           color: AppColors.textSecondary,
           size: 20,
         ),
         onPressed: _toggleObscure,
       );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textDisabled,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _isObscured, // Use local state
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
               color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null 
                  ? Icon(widget.prefixIcon, size: 20, color: _isFocused ? AppColors.primary : AppColors.textSecondary) 
                  : null,
              suffixIcon: activeSuffixIcon,
              // The base styles are inherited from AppTheme.inputDecorationTheme
              // We just handle local overrides or specific states if needed
            ),
          ),
        ),
      ],
    );
  }
}
