import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../tasks/task_detail_page.dart';
import '../../widgets/task_modal.dart';

import '../../widgets/task_grid_card.dart'; // Import

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

enum ViewMode { list, grid }

class _MyTasksPageState extends State<MyTasksPage> {
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MY MISSIONS',
                  style: AppTypography.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontFamily: 'Clash Display'
                  ),
                ).animate().fade().slideX(begin: -0.2, end: 0),
                
                // View Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                         icon: const Icon(Icons.refresh, color: AppColors.textPrimary, size: 20),
                         tooltip: 'Refresh Missions',
                         onPressed: () {
                           context.read<TaskProvider>().fetchTasks();
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing missions...'), duration: Duration(milliseconds: 500)));
                         },
                       ),
                       Container(height: 20, width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 4)),
                      _buildToggleButton(ViewMode.grid, Icons.grid_view_rounded),
                      const SizedBox(width: 4),
                      _buildToggleButton(ViewMode.list, Icons.list_rounded),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 24),

            Expanded(
              child: taskProvider.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: AppColors.textDisabled)
                              .animate().fade().scale(),
                          const SizedBox(height: 16),
                          Text(
                            'No missions assigned.',
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ).animate(delay: 200.ms).fade(),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      clipBehavior: Clip.hardEdge, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           _buildSection("CRITICAL / OVERDUE", taskProvider.tasks.where((t) => t.status != 'Completed' && t.dueBelow != null && t.dueBelow!.isBefore(DateTime.now())).toList(), AppColors.error),
                           _buildSection("PENDING", taskProvider.tasks.where((t) => t.status != 'Completed' && (t.dueBelow == null || t.dueBelow!.isAfter(DateTime.now()))).toList(), AppColors.primary),
                           _buildSection("COMPLETED", taskProvider.tasks.where((t) => t.status == 'Completed').toList(), AppColors.success),
                           const SizedBox(height: 80), 
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(ViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey),
      ),
    );
  }

  Widget _buildSection(String title, List tasks, Color color) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Text(
                title, 
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                )
              ),
              const SizedBox(width: 8),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                 child: Text('${tasks.length}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
        ),
        
        _viewMode == ViewMode.list ? ListView.separated(
          clipBehavior: Clip.hardEdge, 
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
             return TaskCard(
               task: tasks[index],
               index: index,
               onTap: () {
                  TaskModal.show(context, task: tasks[index], isViewing: true);
               },
             );
          },
        ) : LayoutBuilder(
           builder: (context, constraints) {
             int crossAxisCount = 1;
             if (constraints.maxWidth > 1600) {
               crossAxisCount = 6;
             } else if (constraints.maxWidth > 1350) {
               crossAxisCount = 5;
             } else if (constraints.maxWidth > 900) {
               crossAxisCount = 4;
             } else if (constraints.maxWidth > 600) {
               crossAxisCount = 2;
             }

             // Cards should be wider than they are tall (React style)
             // Ratio = Width / Height. > 1.0 means wide.
             double childAspectRatio = 1.25; 
             if (crossAxisCount >= 5) childAspectRatio = 1.15; // Slightly taller in dense grids to prevent overflow
             if (crossAxisCount <= 2) childAspectRatio = 1.6; // Very wide on mobile

             return GridView.builder(
               clipBehavior: Clip.hardEdge,
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: crossAxisCount,
                 crossAxisSpacing: 16,
                 mainAxisSpacing: 16,
                 childAspectRatio: childAspectRatio,
               ),
               itemCount: tasks.length,
               itemBuilder: (context, index) {
                 return TaskGridCard(
                   task: tasks[index],
                   index: index,
                   onTap: () {
                      TaskModal.show(context, task: tasks[index], isViewing: true);
                   },
                 );
               },
             );
           }
        ),
        
        const SizedBox(height: 24),
      ],
    ).animate().fade().slideX();
  }
}

