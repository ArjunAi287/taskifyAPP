import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import 'responsive_builder.dart';

class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int) onNavigationIndexChange;
  final List<AdaptiveScaffoldDestination> destinations;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onNavigationIndexChange,
    required this.destinations,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      // Mobile Layout: Bottom Navigation Bar
      mobileBuilder: (context) => Scaffold(
        backgroundColor: Colors.transparent, // Allow DeepBackground from parent
        appBar: AppBar(
          title: Image.asset(
            'assets/taskify_logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          actions: widget.actions,
        ),
        body: widget.body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onNavigationIndexChange,
          backgroundColor: AppColors.surface.withOpacity(0.8), // Glassy
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: widget.destinations.map((d) {
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            );
          }).toList(),
        ),
        floatingActionButton: widget.floatingActionButton,
      ),
      
      // Tablet Layout: Navigation Rail
      tabletBuilder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Image.asset(
            'assets/taskify_logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          actions: widget.actions,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onNavigationIndexChange,
              backgroundColor: AppColors.surface.withOpacity(0.8), // Glassy
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primary.withOpacity(0.2),
              destinations: widget.destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.divider),
            Expanded(child: widget.body),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      ),
      
      // Desktop Layout: Collapsible Sidebar
      desktopBuilder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Sidebar
            AnimatedContainer(
              duration: 300.ms,
              curve: Curves.easeInOut,
              width: _isSidebarCollapsed ? 80 : 280,
              color: AppColors.surface.withOpacity(0.5), // Glassy Sidebar
              child: Column(
                children: [
                   const SizedBox(height: 32),
                   // App Logo / Title Area
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Row(
                       mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical center
                       children: [
                         InkWell(
                           onTap: _toggleSidebar,
                           borderRadius: BorderRadius.circular(12),
                           child: Container(
                             width: 32,
                             height: 32,
                             alignment: Alignment.center, // Ensure icon stays centered
                             decoration: BoxDecoration(
                               color: AppColors.primary,
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(
                               _isSidebarCollapsed ? Icons.menu : Icons.menu_open, 
                               color: Colors.white,
                               size: 20,
                             ),
                           ),
                         ),
                         
                         if (!_isSidebarCollapsed) ...[
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                                'Taskify',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ).animate().fade().slideX(),
                           ),
                         ],
                       ],
                     ),
                   ),
                   const SizedBox(height: 48),
                   // Navigation Items
                   ...widget.destinations.asMap().entries.map((entry) {
                     final idx = entry.key;
                     final dest = entry.value;
                     final isSelected = idx == widget.currentIndex;
                     return _DesktopNavItem(
                       icon: isSelected ? dest.selectedIcon : dest.icon,
                       label: dest.label,
                       isSelected: isSelected,
                       isCollapsed: _isSidebarCollapsed,
                       onTap: () => widget.onNavigationIndexChange(idx),
                     );
                   }),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.divider),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Desktop Header
                  Container(
                    height: 80,
                    width: double.infinity, // Ensure full width
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/taskify_logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        if (widget.actions != null) Row(children: widget.actions!),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: widget.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      ),
      
      builder: (context) => const SizedBox.shrink(), // Should not happen
    );
  }
}

class AdaptiveScaffoldDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  
  const AdaptiveScaffoldDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _DesktopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.surfaceHighlight,
          child: Tooltip(
            message: isCollapsed ? label : '',
            waitDuration: 500.ms,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8, vertical: 12),
              alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
