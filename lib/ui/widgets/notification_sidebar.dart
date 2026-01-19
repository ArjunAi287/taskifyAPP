import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import './task_modal.dart';

class NotificationSidebar extends StatelessWidget {
  const NotificationSidebar({super.key});

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final user = context.watch<AuthProvider>().user;
    
    // Create notifications from recent tasks (overdue, due today, newly assigned)
    final notifications = <Map<String, dynamic>>[];
    
    if (user != null) {
      final now = DateTime.now();
      
      // Overdue tasks
      for (var task in taskProvider.tasks) {
        if (task.dueBelow != null && task.dueBelow!.isBefore(now) && task.status != 'Completed') {
          if (task.assignedTo == user.id || task.createdBy == user.id) {
            notifications.add({
              'task': task,
              'type': 'overdue',
              'title': 'Task Overdue',
              'message': task.title,
              'time': task.dueBelow,
              'color': AppColors.error,
            });
          }
        }
      }
      
      // Due today tasks
      for (var task in taskProvider.tasks) {
        if (task.dueBelow != null && task.status != 'Completed') {
          if (now.year == task.dueBelow!.year &&
              now.month == task.dueBelow!.month &&
              now.day == task.dueBelow!.day) {
            if (task.assignedTo == user.id) {
              notifications.add({
                'task': task,
                'type': 'due_today',
                'title': 'Due Today',
                'message': task.title,
                'time': task.dueBelow,
                'color': AppColors.warning,
              });
            }
          }
        }
      }
      
      // Recently assigned tasks (created in last 7 days)
      for (var task in taskProvider.tasks) {
        if (task.dueBelow != null) {
          if (task.dueBelow!.isAfter(now.subtract(const Duration(days: 7))) && task.assignedTo == user.id && task.createdBy != user.id && task.status != 'Completed') {
            notifications.add({
              'task': task,
              'type': 'assigned',
              'title': 'New Assignment',
              'message': task.title,
              'time': task.dueBelow,
              'color': AppColors.primary,
            });
          }
        }
      }
    }
    
    // Sort by time (most recent first)
    notifications.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    
    return Drawer(
      backgroundColor: AppColors.surface,
      width: 380,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${notifications.length} notifications',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Notifications List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'re all caught up!',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final task = notification['task'];
                        final type = notification['type'] as String;
                        final title = notification['title'] as String;
                        final message = notification['message'] as String;
                        final time = notification['time'] as DateTime;
                        final color = notification['color'] as Color;
                        
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context); // Close sidebar
                            TaskModal.show(context, task: task, isViewing: true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: color,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatNotificationTime(time),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textDisabled,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (task.priority != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            task.priority.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

