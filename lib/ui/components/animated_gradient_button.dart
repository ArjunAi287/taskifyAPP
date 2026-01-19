
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const AnimatedGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnimation;
  late Animation<double> _radiusAnimation;
  
  // Hover state
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animate the gradient center from top-left to bottom-rightish
    _alignAnimation = Tween<Alignment>(
      begin: const Alignment(-1.0, -1.0),
      end: const Alignment(1.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    // Pulse the radius slightly
    _radiusAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Continuous subtle animation breathing
    // _controller.repeat(reverse: true); 
    // OR just animate on hover? The request implies a specific CSS hover effect.
    // CSS says: transition 0.5s for positions. 
    // Let's make it interactive: On Hover, move the gradient.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    setState(() => _isHovered = true);
    _controller.repeat(reverse: true, period: const Duration(seconds: 2));
  }

  void _onExit(PointerEvent details) {
    setState(() => _isHovered = false);
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isHovered
                    ? [
                         BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
                // The Radial Gradient Background
                gradient: RadialGradient(
                  center: _isHovered ? _alignAnimation.value : Alignment.center,
                  radius: _isHovered ? 2.5 : 3.0, // Spread
                  colors: const [
                    // Mapping "Arctic Stealth" palette to the 5 stops
                    AppColors.primary,       // --color-1: Core Highlight (White/Off-white)
                    Color(0xFFC0C0C0),       // --color-2: Silver (Manual tweak for smoother transition)
                    AppColors.tertiary,      // --color-3: Slate
                    AppColors.secondary,     // --color-4: Graphite
                    Color(0xFF000000),       // --color-5: Black Edge
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                ),
                // Border gradient simulation (simplification: simple border for now)
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black, // Dark loader on light core
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.black, // Always black for high contrast on the "shine"
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
