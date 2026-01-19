import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../layout/adaptive_scaffold.dart';
import '../../../providers/auth_provider.dart';
import '../calendar/calendar_page.dart';
import '../dashboard/dashboard_page.dart';
import '../tasks/my_tasks_page.dart';
import '../settings/settings_page.dart';
import '../../widgets/deep_background.dart';
import '../../widgets/task_modal.dart';
import '../../widgets/notification_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const DashboardPage(),
    const MyTasksPage(),
    const CalendarPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return DeepBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        endDrawer: const NotificationSidebar(),
        body: AdaptiveScaffold(
          title: 'Taskify',
          currentIndex: _currentIndex,
          onNavigationIndexChange: (idx) async {
            setState(() => _currentIndex = idx);
          },
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],
          destinations: const [
            AdaptiveScaffoldDestination(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            AdaptiveScaffoldDestination(
              label: 'My Tasks',
              icon: Icons.check_circle_outline,
              selectedIcon: Icons.check_circle,
            ),
            AdaptiveScaffoldDestination(
              label: 'Calendar',
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
            ),
            AdaptiveScaffoldDestination(
               label: 'Settings',
               icon: Icons.settings_outlined,
               selectedIcon: Icons.settings,
            ),
          ],
          floatingActionButton: _currentIndex == 0 || _currentIndex == 1 
              ? FloatingActionButton(
                  onPressed: () {
                    TaskModal.show(context);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: _screens[_currentIndex >= _screens.length ? 0 : _currentIndex],
        ),
      ),
    );
  }
}
