import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }
enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null) return AppColors.surfaceElevated;
    
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.destructive:
        return AppColors.error;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    if (widget.onPressed == null) return AppColors.textDisabled;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.black; // Dark text on light gradient
      case AppButtonVariant.secondary:
        return Colors.black;
      case AppButtonVariant.destructive:
        return Colors.white;
      case AppButtonVariant.outline:
        return AppColors.textPrimary;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }

  BorderSide _getBorderSide() {
    if (widget.variant == AppButtonVariant.outline) {
      return BorderSide(
        color: _isHovered || _isFocused ? AppColors.primary : AppColors.border,
        width: 1.5,
      );
    }
    return BorderSide.none;
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case AppButtonSize.small: return 12;
      case AppButtonSize.medium: return 14;
      case AppButtonSize.large: return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Focus(
            onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
            child: SizedBox(
              width: widget.isFullWidth ? double.infinity : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.variant == AppButtonVariant.primary ? null : _getBackgroundColor().withOpacity(
                    (_isHovered || _isFocused) && widget.variant != AppButtonVariant.outline ? 0.9 : 1.0,
                  ),
                  gradient: widget.variant == AppButtonVariant.primary ? AppColors.stealthGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.fromBorderSide(_getBorderSide()),
                  boxShadow: (_isHovered || _isFocused) && widget.variant == AppButtonVariant.primary
                      ? [
                          BoxShadow(
                            color: AppColors.glowPrimary, // Use the specific glow color
                            blurRadius: 16, // Increased blur for better glow
                            offset: const Offset(0, 4),
                            spreadRadius: 2, // Add spread
                          )
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLoading ? null : widget.onPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: _getPadding(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isLoading) ...[
                             SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2, 
                                color: _getForegroundColor(),
                              )
                            ),
                             const SizedBox(width: 8),
                          ] else if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: _getForegroundColor()),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: _getForegroundColor(),
                              fontSize: _getFontSize(),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
