import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DeepBackground extends StatelessWidget {
  final Widget child;

  const DeepBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Void
        Container(
          color: AppColors.background,
        ),
        
        // Nebula 1 (Top Left - Primary/Mint)
        Positioned(
          top: -200,
          left: -200,
          width: 600,
          height: 600,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
        
        // Nebula 2 (Bottom Right - Secondary/Magenta)
        Positioned(
          bottom: -200,
          right: -200,
          width: 600,
          height: 600,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}
