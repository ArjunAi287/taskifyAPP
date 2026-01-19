import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../tasks/task_detail_page.dart';
import '../../widgets/task_modal.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final taskProvider = context.watch<TaskProvider>();
    
    // Auth Guard: Handle direct URL access or missing auth
    if (authProvider.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Prevent infinite loop if already on login
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox(); 
    }

    if (authProvider.status == AuthStatus.unknown) {
       // Try to init auth if we skipped AuthWrapper
       WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuthProvider>().initAuth();
       });
       return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Calculate all dashboard metrics
    final userId = user.id;
    final allTasks = taskProvider.tasks;

    // FALLBACK: Empty State if no tasks
    if (allTasks.isEmpty && !taskProvider.isLoading) {
      return _buildEmptyDashboard(user);
    }

    // Your Workload
    final assignedToMe = allTasks.where((t) => t.assignedTo == userId).length;
    final createdByMe = allTasks.where((t) => t.createdBy == userId).length;
    final reviewingTasks = allTasks.where((t) => 
      t.reviewers.any((r) => r.id == userId)
    ).length;

    // Task Health Score
    final activeTasks = allTasks.where((t) => t.status != 'Completed').toList();
    final now = DateTime.now();
    final onTrackTasks = activeTasks.where((t) => 
      t.dueBelow == null || t.dueBelow!.isAfter(now.add(const Duration(days: 2)))
    ).length;
    final atRiskTasks = activeTasks.where((t) => 
      t.dueBelow != null && 
      t.dueBelow!.isAfter(now) && 
      t.dueBelow!.isBefore(now.add(const Duration(days: 2)))
    ).length;
    final overdueTasks = activeTasks.where((t) => 
      t.dueBelow != null && t.dueBelow!.isBefore(now)
    ).length;
    
    // Fallback for calculation (though isEmpty check above handles most cases)
    final healthScore = activeTasks.isEmpty ? 100 : 
      ((onTrackTasks + atRiskTasks * 0.5) / activeTasks.length * 100).round();

    // Completion Detail
    final tasksAssignedToMe = allTasks.where((t) => t.assignedTo == userId).toList();
    final myCompletedCount = tasksAssignedToMe.where((t) => t.status == 'Completed').length;
    final myTotalAssigned = tasksAssignedToMe.length;
    final myCompletionRate = myTotalAssigned == 0 ? 0 : 
      (myCompletedCount / myTotalAssigned * 100).round();

    final tasksIAssigned = allTasks.where((t) => 
      t.createdBy == userId && t.assignedTo != userId
    ).toList();
    final othersCompletedCount = tasksIAssigned.where((t) => t.status == 'Completed').length;
    final othersTotal = tasksIAssigned.length;
    final othersCompletionRate = othersTotal == 0 ? 0 : 
      (othersCompletedCount / othersTotal * 100).round();

    // High Priority Tasks
    final highPriorityTasks = allTasks.where((t) => 
      t.priority.toLowerCase() == 'high' && t.status != 'Completed'
    ).toList();

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header (Hello + Date/Time)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -2,
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(
                      'Hello, ${user?.fullName?.split(' ').first ?? "User"}',
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Clash Display',
                      ),
                    ).animate().fade().slideX(begin: -0.2, end: 0),
                    Text(
                      'Ready for your mission?',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                         color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Live Date/Time
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                  builder: (context, snapshot) {
                     final now = DateTime.now();
                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text(
                           DateFormat('HH:mm').format(now),
                           style: const TextStyle(
                             color: AppColors.primary,
                             fontSize: 32,
                             fontWeight: FontWeight.w900,
                             fontFamily: 'Clash Display',
                             letterSpacing: 2
                           ),
                         ),
                         Text(
                           DateFormat('EEE, MMM d').format(now).toUpperCase(),
                           style: TextStyle(
                             color: AppColors.textSecondary.withOpacity(0.8),
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                             letterSpacing: 1.5
                           ),
                         ),
                       ],
                     );
                  },
                ),
              ],
            ),
          ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 24),
          
          Text(
            "OVERVIEW",
             style: AppTypography.textTheme.labelMedium?.copyWith(
               color: AppColors.textSecondary,
               letterSpacing: 2,
               fontWeight: FontWeight.bold,
             ),
          ).animate().fade().slideX(),
          
          const SizedBox(height: 16),

            // Responsive Stats Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700; // Lowered breakpoint for 1366x768 screens
              
              final workloadCard = _buildWorkloadCard(assignedToMe, createdByMe, reviewingTasks, isMobile);
              final healthCard = _buildHealthScoreCard(healthScore, onTrackTasks, atRiskTasks, overdueTasks, isMobile);
              final completionCard = _buildCompletionDetailCard(
                myCompletedCount, myTotalAssigned, myCompletionRate,
                othersCompletedCount, othersTotal, othersCompletionRate, isMobile
              );
              final highPriorityCard = _buildHighPriorityCountCard(highPriorityTasks.length, isMobile);

              if (isMobile) {
                // 2x2 Grid for Mobile
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: workloadCard),
                          const SizedBox(width: 12),
                          Expanded(child: healthCard),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: completionCard),
                          const SizedBox(width: 12),
                          Expanded(child: highPriorityCard),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // 4x1 Row for Desktop
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       Expanded(child: workloadCard),
                       const SizedBox(width: 16),
                       Expanded(child: healthCard),
                       const SizedBox(width: 16),
                       Expanded(child: completionCard),
                       const SizedBox(width: 16),
                       Expanded(child: highPriorityCard),
                    ],
                  ),
                );
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // High Priority Tasks Section
          if (highPriorityTasks.isNotEmpty) ...[
            Text(
              "HIGH PRIORITY TASKS",
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade().slideX(),
            
            const SizedBox(height: 16),
            
            _buildHighPriorityTasksList(highPriorityTasks),
            
            const SizedBox(height: 24),
          ],
          
          // Today's Tasks Section
          Text(
            "TODAY'S TASKS",
             style: AppTypography.textTheme.labelMedium?.copyWith(
               color: AppColors.textSecondary,
               letterSpacing: 2,
               fontWeight: FontWeight.bold,
             ),
          ).animate().fade().slideX(),
          
          const SizedBox(height: 16),
          
          // Today's Tasks List
          Builder(
            builder: (context) {
              final today = DateTime.now();
              final todayTasks = taskProvider.tasks.where((t) {
                if (t.dueBelow == null) return false;
                return t.dueBelow!.year == today.year &&
                       t.dueBelow!.month == today.month &&
                       t.dueBelow!.day == today.day;
              }).toList();
              
              if (todayTasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available, size: 32, color: AppColors.textDisabled)
                            .animate().fade().scale(),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks due today',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ).animate(delay: 200.ms).fade(),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: todayTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTodayTaskCard(task),
                )).toList(),
              );
            },
          ),
          
          const SizedBox(height: 80), // Bottom spacing for FAB
        ],
      ),
    );
  }
  
  Widget _buildTodayTaskCard(dynamic task) {
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = AppColors.error;
        break;
      case 'medium':
        priorityColor = AppColors.warning;
        break;
      default:
        priorityColor = AppColors.primary;
    }
    
    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.status,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade().slideX(begin: 0.1, end: 0);

    return InkWell(
      onTap: () {
        TaskModal.show(context, task: task, isViewing: true);
      },
      child: cardContent,
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceElevated.withOpacity(0.8), // subtle gradient
          ]
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.arrow_outward, color: AppColors.textSecondary.withOpacity(0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontFamily: 'Clash Display',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWorkloadCard(int assigned, int created, int reviewing, bool isMobile) {
    String loadLevel;
    Color loadColor;
    final totalLoad = assigned + reviewing;
    
    if (totalLoad >= 15) {
      loadLevel = 'HIGH';
      loadColor = AppColors.error;
    } else if (totalLoad >= 8) {
      loadLevel = 'MEDIUM';
      loadColor = AppColors.warning;
    } else {
      loadLevel = 'LOW';
      loadColor = AppColors.success;
    }
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work_outline, color: AppColors.primary, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: loadColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loadLevel,
                  style: TextStyle(
                    color: loadColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conditional layout based on screen size
              if (isMobile) ...[
                // Mobile: Vertical list
                Row(
                  children: [
                    const Text(
                      'Assigned: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$assigned',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'Clash Display',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Created: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$created',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'Clash Display',
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Desktop: Horizontal layout
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Assigned: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$assigned',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Clash Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Created: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$created',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Clash Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Reviewing: $reviewing',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'YOUR WORKLOAD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(int score, int onTrack, int atRisk, int overdue, bool isMobile) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety_outlined, color: scoreColor, size: 20),
              ),
              Icon(Icons.arrow_outward, color: AppColors.textSecondary.withOpacity(0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                  fontFamily: 'Clash Display',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildHealthDot(AppColors.success),
                  const SizedBox(width: 4),
                  Text('On Track: $onTrack', style: _healthSubStyle()),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _buildHealthDot(AppColors.warning),
                  const SizedBox(width: 4),
                  Text('At Risk: $atRisk', style: _healthSubStyle()),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _buildHealthDot(AppColors.error),
                  const SizedBox(width: 4),
                  Text('Overdue: $overdue', style: _healthSubStyle()),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'TASK HEALTH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHealthDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  TextStyle _healthSubStyle() {
    return const TextStyle(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
  }

  Widget _buildCompletionDetailCard(
    int myCompleted, int myTotal, int myRate,
    int othersCompleted, int othersTotal, int othersRate, bool isMobile
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              ),
              Icon(Icons.arrow_outward, color: AppColors.textSecondary.withOpacity(0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Tasks
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'You: ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$myCompleted/$myTotal',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Clash Display',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($myRate%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: myRate >= 70 ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Others' Tasks
              Row(
                children: [
                  const Icon(Icons.group, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Others: ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$othersCompleted/$othersTotal',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Clash Display',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($othersRate%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: othersRate >= 70 ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'COMPLETION RATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHighPriorityCountCard(int count, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, color: AppColors.error, size: 20),
              ),
              Icon(Icons.arrow_outward, color: AppColors.textSecondary.withOpacity(0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontFamily: 'Clash Display',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'HIGH PRIORITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHighPriorityTasksList(List<dynamic> tasks) {
    // Show max 5 tasks
    final displayTasks = tasks.take(5).toList();
    final remainingCount = tasks.length - displayTasks.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'CRITICAL MISSIONS',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayTasks.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => TaskModal.show(context, task: task, isViewing: true),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.dueBelow != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.dueBelow!.isBefore(DateTime.now()) 
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDueDate(task.dueBelow!),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: task.dueBelow!.isBefore(DateTime.now()) 
                            ? AppColors.error
                            : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
          if (remainingCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+ $remainingCount more',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      final days = difference.inDays.abs();
      if (days == 0) return 'OVERDUE';
      return 'OVERDUE ${days}d';
    }
    
    if (difference.inDays == 0) return 'TODAY';
    if (difference.inDays == 1) return 'TOMORROW';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    return DateFormat('MMM d').format(dueDate);
  }

  MaterialPageRoute materialPageRoute({required Widget Function(dynamic _) builder}) {
    return MaterialPageRoute(builder: builder);
  }

  Widget _buildEmptyDashboard(dynamic user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ).animate().fade().scale(),
            const SizedBox(height: 24),
            Text(
              "Welcome, ${user.fullName.split(' ').first}!",
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            Text(
              "You don't have any tasks yet.\nCreate your first task to get started.",
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0, delay: 200.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                 TaskModal.show(context);
              },
              icon: const Icon(Icons.add),
              label: const Text("Create First Task"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ).animate().fade().scale(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
