import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../components/app_card.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_typography.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final int index; // For staggered animation

  const TaskCard({super.key, required this.task, this.onTap, this.index = 0});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isHovered = false;

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          // transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0), // Removed scale to prevent overlap
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isHovered 
                  ? [BoxShadow(color: _getPriorityColor(widget.task.priority).withOpacity(0.15), blurRadius: 12, spreadRadius: 0)]
                  : [],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Neon Priority Strip
                    Container(
                      width: 6, // Fixed width to prevent layout jitter
                      decoration: BoxDecoration(
                        color: _getPriorityColor(widget.task.priority),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        boxShadow: [
                            BoxShadow(
                              color: _getPriorityColor(widget.task.priority).withOpacity(_isHovered ? 0.8 : 0.4), // Animate glow
                              blurRadius: _isHovered ? 12 : 6,
                              spreadRadius: _isHovered ? 2 : 0, 
                            )
                        ]
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.task.description!,
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (widget.task.dueBelow != null)
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(widget.task.dueBelow!),
                                        style: AppTypography.textTheme.bodySmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                const Spacer(), // Force status to right
                                  Row(
                                    children: [
                                       if (widget.task.creatorName != null)
                                        Row(
                                          children: [
                                             const Text("BY: ", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                             ConstrainedBox(
                                               constraints: const BoxConstraints(maxWidth: 80),
                                               child: Text(
                                                 widget.task.createdBy == context.read<AuthProvider>().user?.id ? 'Me' : widget.task.creatorName!,
                                                 style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                                                 overflow: TextOverflow.ellipsis,
                                                 maxLines: 1,
                                               ),
                                             )
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                    if (widget.task.assignedTo != null)
                                      Row(
                                        children: [
                                          const Text("TO: ", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          CircleAvatar(
                                            radius: 8, // Smaller radius to fit text
                                            backgroundColor: AppColors.surfaceElevated,
                                            child: Text(
                                              _getInitials(widget.task.assigneeName ?? widget.task.assigneeEmail),
                                              style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 80),
                                            child: Text(
                                              widget.task.assignedTo == context.read<AuthProvider>().user?.id ? 'Me' : (widget.task.assigneeName ?? widget.task.assigneeEmail ?? 'Unknown'),
                                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),

                                    // Reviewers
                                    if (widget.task.reviewers.isNotEmpty) ...[
                                      Container(
                                        height: 24,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (int i = 0; i < widget.task.reviewers.length && i < 3; i++)
                                              Align(
                                                widthFactor: 0.7,
                                                child: CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: AppColors.surface,
                                                  child: CircleAvatar(
                                                    radius: 9,
                                                    backgroundColor: AppColors.primary.withOpacity(0.2),
                                                    child: Text(
                                                      widget.task.reviewers[i].fullName.isNotEmpty 
                                                          ? widget.task.reviewers[i].fullName[0].toUpperCase() 
                                                          : '?',
                                                      style: const TextStyle(fontSize: 8, color: AppColors.primary),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (widget.task.reviewers.length > 3)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: AppColors.surfaceElevated,
                                                  child: Text(
                                                    '+${widget.task.reviewers.length - 3}',
                                                    style: const TextStyle(fontSize: 9, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.divider),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 100),
                                      child: Text(
                                        widget.task.status,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: AppTypography.textTheme.labelSmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.5
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: (widget.index * 50).ms)
     .fade(duration: 400.ms)
     .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }
}
