
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class ConfettiAuthButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final VoidCallback onSuccess;
  final double? width;
  final double height;

  const ConfettiAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.onSuccess,
    this.width,
    this.height = 56,
  });

  @override
  State<ConfettiAuthButton> createState() => _ConfettiAuthButtonState();
}

enum ButtonState { idle, loading, success }

class _ConfettiAuthButtonState extends State<ConfettiAuthButton>
    with SingleTickerProviderStateMixin {
  ButtonState _state = ButtonState.idle;
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_state != ButtonState.idle) return;

    setState(() => _state = ButtonState.loading);

    try {
      // Execute the async task (login/signup)
      await widget.onPressed();

      // If successful:
      if (mounted) {
        setState(() => _state = ButtonState.success);
        _confettiController.play();

        // Wait for visual feedback before navigating
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
        
        if (mounted) {
          widget.onSuccess();
          // Reset state naturally? Or depends on if page gets popped.
          // Usually page is replaced, so this dispose gets called.
        }
      }
    } catch (e) {
      // Reset to idle on error
      if (mounted) {
        setState(() => _state = ButtonState.idle);
        // Error handling should be done by the parent usually, 
        // but we assume the parent showed a snackbar or something if it threw.
        // If the parent handles error internally and returns normally, we might wrongly show success.
        // *Protocol*: onPressed should throw on failure.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Confetti Blast
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: -pi / 2, // Upwards
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          maxBlastForce: 20,
          minBlastForce: 10,
          gravity: 0.3,
          colors: const [
            AppColors.primary,
            AppColors.primaryVariant,
            Colors.white,
            Colors.grey,
          ],
        ),

        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: _handlePress,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), // Rounded pill like React component
                  gradient: _state == ButtonState.success
                      ? const LinearGradient(
                          colors: [AppColors.surface, AppColors.surfaceElevated], // Obsidian
                        )
                      : (_state == ButtonState.loading
                          ? const LinearGradient(colors: [AppColors.surfaceHighlight, AppColors.surfaceHighlight])
                          : AppColors.stealthGradient), // White/Silver
                  boxShadow: _state == ButtonState.idle && _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                  border: Border.all(
                    color: _state == ButtonState.success 
                        ? Colors.green.withOpacity(0.3) 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case ButtonState.loading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
      
      case ButtonState.success:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: Colors.green, size: 20)
                .animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 8),
            Text(
              "Successful!",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ).animate().fade().slideY(begin: 0.5, end: 0),
          ],
        );

      case ButtonState.idle:
      default:
        // React component had the "Spark" overlay. 
        // We simulate a clean high-contrast look for now, as complex CSS masks are hard in Flutter.
        return Text(
          widget.label,
          style: const TextStyle(
            color: Colors.black, // High contrast on Stealth Gradient
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        );
    }
  }
}
