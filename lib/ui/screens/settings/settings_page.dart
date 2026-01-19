import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SETTINGS',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontFamily: 'Clash Display',
              ),
            ).animate().fade().slideX(begin: -0.2, end: 0),
            
            const SizedBox(height: 32),
            
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName?.isNotEmpty == true 
                                ? user!.fullName![0].toUpperCase() 
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // Account Section
            Text(
              'ACCOUNT',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: 200.ms).fade(),
            
            const SizedBox(height: 12),
            
            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/login', 
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Logout',
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
            
            const Spacer(),
            
            // App Version
            Center(
              child: Text(
                'Taskify v1.0.0',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ).animate(delay: 400.ms).fade(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
