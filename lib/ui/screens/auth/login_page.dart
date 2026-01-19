import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import '../../../providers/auth_provider.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/confetti_auth_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/deep_background.dart';
import 'signup_page.dart';
import 'package:dio/dio.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) throw Exception("Invalid Form");
    
    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Login Failed';
        if (e.response?.data != null && e.response!.data is Map) {
          msg = e.response!.data['msg'] ?? e.message ?? 'Unknown';
        } else {
           msg = e.message ?? 'Unknown';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
      rethrow;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // "Anti-Slop" Layout: Asymmetric, floating elements, deep void.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final isMobileSmall = constraints.maxWidth < 400;

            return Stack(
              children: [
                // 1. Kinetic Typography (Background Layer)
                Positioned(
                  top: isDesktop ? 60 : 80,
                  left: isDesktop ? 60 : 24,
                  right: isDesktop ? null : 24, // Constrain width on mobile
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKineticText("LOCKED", delay: 0.ms),
                      _buildKineticText("IN", delay: 300.ms, isGradient: true),
                    ],
                  ),
                ),

                // 2. Glassmorphic Login Form (Floating)
                Align(
                  alignment: isDesktop ? Alignment.centerRight : Alignment.bottomCenter,
                  child: Container(
                    width: isDesktop ? 500 : double.infinity,
                    // Mobile: Adapts to content but has min height for presence
                    constraints: isDesktop 
                       ? null 
                       : BoxConstraints(
                           maxHeight: constraints.maxHeight * 0.85,
                         ),
                    margin: isDesktop 
                        ? const EdgeInsets.only(right: 100) 
                        : const EdgeInsets.only(top: 150), // Overlaps slighty with text
                    padding: EdgeInsets.all(isMobileSmall ? 24 : 40),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.4), // Glassy
                      borderRadius: isDesktop 
                          ? BorderRadius.circular(32)
                          : const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Login",
                                style: AppTypography.textTheme.headlineLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: isMobileSmall ? 32 : null,
                                ),
                              ).animate().fade().slideX(begin: 0.2, end: 0),
                              
                              const SizedBox(height: 8),
                              Text(
                                "Welcome back.",
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ).animate(delay: 100.ms).fade().slideX(begin: 0.2, end: 0),

                              SizedBox(height: isMobileSmall ? 32 : 48),

                              // Inputs
                              AppTextField(
                                label: 'Email',
                                hint: 'user@example.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                              ).animate(delay: 200.ms).fade().slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 24),
                              
                              AppTextField(
                                label: 'Password',
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                              ).animate(delay: 300.ms).fade().slideY(begin: 0.2, end: 0),

                              SizedBox(height: isMobileSmall ? 32 : 48),

                              // Actions
                              ConfettiAuthButton(
                                label: 'Login',
                                onPressed: _login,
                                onSuccess: () {
                                  // Clear stack and go to dashboard
                                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                                },
                                width: double.infinity,
                              ).animate(delay: 400.ms).fade().scale(),

                              const SizedBox(height: 32),
                              
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) => const SignupPage(),
                                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                      children: [
                                        TextSpan(
                                          text: "Sign Up",
                                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate(delay: 600.ms).fade(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 800.ms, curve: Curves.easeOutCirc)
                   .slideX(begin: isDesktop ? 0.2 : 0, end: 0)
                   .slideY(begin: isDesktop ? 0 : 0.2, end: 0),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKineticText(String text, {required Duration delay, bool isGradient = false}) {
    // FittedBox ensures the massive text wraps/scales down on mobile
    if (isGradient) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: GradientText(
          text,
          colors: const [AppColors.primary, AppColors.secondary],
          style: AppTypography.textTheme.displayLarge?.copyWith(
            fontSize: 120, // Huge base size for impact
            fontWeight: FontWeight.w900,
            height: 0.85,
            letterSpacing: -4.0,
          ),
        ),
      ).animate().fade(delay: delay, duration: 1000.ms).moveX(begin: -50, end: 0, duration: 1000.ms, curve: Curves.easeOutExpo);
    }
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: AppTypography.textTheme.displayLarge?.copyWith(
            fontSize: 120,
            fontWeight: FontWeight.w900,
            height: 0.85,
            color: AppColors.textPrimary.withOpacity(0.5), // More visible
            letterSpacing: -4.0,
          ),
        ),
      ),
    ).animate().fade(delay: delay, duration: 1000.ms).moveX(begin: -50, end: 0, duration: 1000.ms, curve: Curves.easeOutExpo);
  }
}

