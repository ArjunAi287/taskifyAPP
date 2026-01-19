import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/deep_background.dart';
import '../auth/login_page.dart';

class StoryIntroPage extends StatefulWidget {
  const StoryIntroPage({super.key});

  @override
  State<StoryIntroPage> createState() => _StoryIntroPageState();
}

class _StoryIntroPageState extends State<StoryIntroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Kinetic Typography Sequence
                _buildAnimatedText("ZERO", delay: 200.ms),
                const SizedBox(height: 8),
                _buildAnimatedText("NOISE", delay: 800.ms, color: AppColors.secondary),
                 const SizedBox(height: 8),
                _buildGradientText("PURE FLOW.", delay: 1600.ms),
                
                const Spacer(),
                
                // Narrative Text
                Text(
                  "Silence the chaos. Amplify the output.",
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fade(delay: 2000.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 48),
                
                // Action Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginPage(),
                          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                          transitionDuration: 800.ms,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.glowPrimary,
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "ENTER FLOW",
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .boxShadow(
                    begin: const BoxShadow(color: AppColors.glowPrimary, blurRadius: 20),
                    end: const BoxShadow(color: AppColors.glowPrimary, blurRadius: 40, spreadRadius: 5),
                    duration: 2.seconds,
                  )
                  .animate().fade(delay: 2500.ms).slideY(begin: 0.5, end: 0),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText(String text, {required Duration delay, Color? color}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.textTheme.displayLarge?.copyWith(
          fontSize: 80, // Larger base size, lets FittedBox scale it
          fontWeight: FontWeight.w900,
          height: 0.9,
          color: color ?? AppColors.textPrimary,
          letterSpacing: -2.0,
        ),
      ),
    ).animate().fade(duration: 600.ms, delay: delay)
     .moveY(begin: 20, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
  
  Widget _buildGradientText(String text, {required Duration delay}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: GradientText(
        text,
        textAlign: TextAlign.center,
        colors: const [AppColors.primary, AppColors.secondary],
        style: AppTypography.textTheme.displayLarge?.copyWith(
          fontSize: 80,
          fontWeight: FontWeight.w900,
          height: 0.9,
          letterSpacing: -2.0,
        ),
      ),
    ).animate().fade(duration: 800.ms, delay: delay)
     .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 800.ms)
     .shimmer(duration: 2.seconds, delay: 2.seconds);
  }
}
