import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'login_page.dart';
import '../home/home_screen.dart';
import '../intro/story_intro_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.status == AuthStatus.unknown) {
           return Scaffold(
             backgroundColor: AppColors.background,
             body: Center(
               child: CircularProgressIndicator(color: AppColors.primary),
             ),
           );
        }
        if (auth.status == AuthStatus.authenticated) {
          return const HomeScreen();
        }
        return const StoryIntroPage();
      },
    );
  }
}
