import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/deep_background.dart';
import '../../widgets/task_modal.dart';
class TaskDetailPage extends StatelessWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  void _addReviewer(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add Reviewer', style: AppTypography.textTheme.titleLarge),
        content: SizedBox(
          width: 400,
          child: AppTextField(
            label: 'Reviewer Email',
            hint: 'email@example.com',
            controller: emailController,
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Add',
            size: AppButtonSize.small,
            onPressed: () async {
              try {
                await context.read<TaskProvider>().addReviewer(task.id, emailController.text.trim());
                if (ctx.mounted) {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reviewer Added'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (ctx.mounted) {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteTask(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Task', style: AppTypography.textTheme.titleLarge),
        content: Text('Are you sure you want to delete this task?', style: AppTypography.textTheme.bodyMedium),
        actions: [
          TextButton(child: Text('No', style: TextStyle(color: AppColors.textSecondary)), onPressed: () => Navigator.pop(ctx, false)),
          AppButton(
             label: 'Yes, Delete', 
             variant: AppButtonVariant.destructive,
             size: AppButtonSize.small,
             onPressed: () => Navigator.pop(ctx, true)
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      try {
        await context.read<TaskProvider>().deleteTask(task.id);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await context.read<TaskProvider>().updateTask(id: task.id, status: newStatus);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppColors.success));
         Navigator.pop(context); // Close detail page to refresh list or we rely on provider notify
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;
    final isCreator = task.createdBy == myId;
    final isAssignee = task.assignedTo == myId;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for DeepBackground
      body: DeepBackground(
        child: Column(
          children: [
              AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Task Details'),
              leading: BackButton(color: AppColors.textPrimary),
              actions: [
                if (isCreator || isAssignee)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => TaskModal(task: task, isViewing: false)) // Open in Edit Mode
                    ),
                  ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _deleteTask(context),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: AppTypography.textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTag(_getPriorityColor(task.priority), task.priority, isOutlined: true),
                const SizedBox(width: 8),
                _buildTag(AppColors.textSecondary, task.status),
              ],
            ),
            const SizedBox(height: 32),
            AppCard(
              padding: const EdgeInsets.all(24),
              enableHover: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Text(
                    task.description ?? 'No description provided.',
                    style: AppTypography.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
             if (task.dueBelow != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  enableHover: false,
                  child: Row(
                    children: [
                      Icon(Icons.event, color: AppColors.primary, size: 24),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Due Date', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                           Text(
                             DateFormat('MMMM d, y  •  h:mm a').format(task.dueBelow!),
                             style: AppTypography.textTheme.titleMedium,
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
             ],
             if (task.assigneeName != null || task.assigneeEmail != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  enableHover: false,
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.secondary, size: 24),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Assigned To', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                           Text(
                             task.assigneeName ?? task.assigneeEmail ?? 'Unknown',
                             style: AppTypography.textTheme.titleMedium,
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
             ],

             if (task.reviewers.isNotEmpty) ...[
                Text('Reviewers', style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: task.reviewers.map((r) => Chip(
                    label: Text(r.fullName.isNotEmpty ? r.fullName : r.email),
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: AppTypography.textTheme.bodySmall,
                  )).toList(),
                ),
                const SizedBox(height: 24),
             ],

            if (isCreator || isAssignee) ...[
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              
              // Status Actions
              if (isAssignee && task.status == 'Open')
                 AppButton(
                  label: 'Start Work',
                  icon: Icons.play_arrow,
                  onPressed: () => _updateStatus(context, 'Work In Progress'),
                  isFullWidth: true,
                ),
              if (isAssignee && task.status == 'Work In Progress')
                 AppButton(
                  label: 'Complete Task',
                  icon: Icons.check,
                  variant: AppButtonVariant.primary, // or success color
                  onPressed: () => _updateStatus(context, 'Completed'),
                  isFullWidth: true,
                ),
              if (isCreator && task.status == 'Completed')
                 AppButton(
                  label: 'Reopen Task',
                  icon: Icons.refresh,
                  variant: AppButtonVariant.outline,
                  onPressed: () => _updateStatus(context, 'Open'), // Reset to Open
                  isFullWidth: true,
                ),

              const SizedBox(height: 16),
              if (isCreator)
                AppButton(
                  label: 'Add Reviewer',
                  icon: Icons.person_add,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _addReviewer(context),
                  isFullWidth: true,
                ),
            ],
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(Color color, String label, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? color.withOpacity(0.1) : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: isOutlined ? color : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }
}
