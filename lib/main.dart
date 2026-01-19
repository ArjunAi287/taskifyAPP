import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'ui/screens/auth/auth_wrapper.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/auth/login_page.dart';
import 'services/notification_service.dart';
import 'ui/widgets/task_modal.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print current configuration
  AppConfig.printConfig();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint("Failed to initialize notifications (Non-fatal): $e");
  }
  
  // Register callback to handle notification taps
  notificationService.setNotificationTapCallback((taskId) {
    debugPrint('📌 Notification tap callback triggered for task ID: $taskId');
    
    // Get the current context from navigator
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Fetch the specific task from the provider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = taskProvider.tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => taskProvider.tasks.first, // Fallback if not found
      );
      
      // Open the task modal
      TaskModal.show(context, task: task, isViewing: true);
      debugPrint('✅ Opened task modal for task ID: $taskId');
    } else {
      debugPrint('⚠️ No context available for navigation');
    }
  });
  
  // Request Permissions (Non-blocking on mobile/desktop, prompt on web)
  try {
     notificationService.requestPermissions();
  } catch (e) {
     debugPrint("Error requesting permissions: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Register global navigator key
        title: 'Taskify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // home: const AuthWrapper(), // Removed because '/' route is defined below
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/dashboard': (context) => HomeScreen(),
          '/login': (context) => LoginPage(),
          // '/signup': (context) => const SignupPage(), 
        },
      ),
    );
  }
}
