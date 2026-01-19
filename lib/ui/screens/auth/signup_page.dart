import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import '../../../providers/auth_provider.dart';
import 'package:dio/dio.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/confetti_auth_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/deep_background.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) throw Exception("Invalid Form");

    try {
      await context.read<AuthProvider>().signup(
            _fullNameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _confirmPasswordController.text.trim(),
          );
      // Success handled by button callback
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Signup Failed';
        if (e.response?.data != null && e.response!.data is Map) {
          errorMessage = e.response!.data['msg'] ?? e.message ?? 'Unknown Error';
        } else {
           errorMessage = e.message ?? 'Unknown Error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
      rethrow;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed: $e'), backgroundColor: AppColors.error),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final isMobileSmall = constraints.maxWidth < 400;

            return Stack(
              children: [
                // 1. Kinetic Typography (Background Layer) - Mirrored/Different position than Login
                Positioned(
                  bottom: isDesktop ? 60 : null,
                  top: isDesktop ? null : 60,
                  left: isDesktop ? 60 : 24,
                  right: isDesktop ? null : 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKineticText("GAME", delay: 0.ms),
                      _buildKineticText("TIME", delay: 300.ms, isGradient: true),
                    ],
                  ),
                ),

                // 2. Glassmorphic Signup Form (Floating)
                Align(
                  alignment: isDesktop ? Alignment.centerRight : Alignment.bottomCenter,
                  child: Container(
                    width: isDesktop ? 500 : double.infinity,
                    // Mobile: Max height constraints to prevent overflow
                     constraints: isDesktop 
                       ? null 
                       : BoxConstraints(
                           maxHeight: constraints.maxHeight * 0.85,
                         ),
                    margin: isDesktop 
                        ? const EdgeInsets.only(right: 100) 
                        : const EdgeInsets.only(top: 150),
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
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                                    onPressed: () => Navigator.pop(context),
                                  ).animate().fade().slideX(begin: -0.2, end: 0),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Sign Up",
                                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: isMobileSmall ? 24 : null,
                                    ),
                                  ).animate().fade().slideX(begin: 0.2, end: 0),
                                ],
                              ),
                              
                              SizedBox(height: isMobileSmall ? 24 : 32),

                              // Inputs
                              AppTextField(
                                label: 'Full Name',
                                hint: 'John Doe',
                                controller: _fullNameController,
                                prefixIcon: Icons.badge_outlined,
                                validator: (v) => v!.isEmpty ? 'Name is required' : null,
                              ).animate(delay: 200.ms).fade().slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 24),

                              AppTextField(
                                label: 'Email',
                                hint: 'user@example.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (v) => v!.isEmpty ? 'Email is required' : null,
                              ).animate(delay: 300.ms).fade().slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 24),
                              
                              AppTextField(
                                label: 'Password',
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                validator: (v) => v!.length < 6 ? 'Password must be at least 6 chars' : null,
                              ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 24),

                              AppTextField(
                                label: 'Confirm Password',
                                hint: '••••••••',
                                controller: _confirmPasswordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_clock_outlined,
                                validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                              ).animate(delay: 500.ms).fade().slideY(begin: 0.2, end: 0),

                              SizedBox(height: isMobileSmall ? 32 : 48),

                              // Actions
                              ConfettiAuthButton(
                                label: 'Sign Up',
                                onPressed: _signup,
                                onSuccess: () {
                                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                                },
                                width: double.infinity,
                              ).animate(delay: 600.ms).fade().scale(),
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
    if (isGradient) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: GradientText(
          text,
          colors: const [AppColors.primary, AppColors.secondary],
          style: AppTypography.textTheme.displayLarge?.copyWith(
            fontSize: 120,
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
