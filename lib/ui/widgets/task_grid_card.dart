import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../components/app_card.dart';

class TaskGridCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final int index;

  const TaskGridCard({super.key, required this.task, this.onTap, this.index = 0});

  @override
  State<TaskGridCard> createState() => _TaskGridCardState();
}

class _TaskGridCardState extends State<TaskGridCard> {
  bool _isHovered = false;

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
     switch (status) {
       case 'Completed': return AppColors.success;
       case 'Work In Progress': return AppColors.warning;
       default: return Colors.blue;
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
    final user = context.read<AuthProvider>().user;
    final isCompleted = widget.task.status == 'Completed';
    final date = widget.task.dueBelow ?? DateTime.now();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF212229) : const Color(0xFF1A1B21), // Hover effect: Lighter BG
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(
              color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05)
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ] : [],
          ),
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date/Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d').format(date).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              DateFormat('h:mm').format(date),
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat('a').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pills
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status Pill
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100), // constrain width
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.task.status).withOpacity(0.1),
                          border: Border.all(color: _getStatusColor(widget.task.status).withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          widget.task.status.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _getStatusColor(widget.task.status),
                            fontSize: 9, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Priority Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                          color: _getPriorityColor(widget.task.priority).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          widget.task.priority.toUpperCase(),
                          style: TextStyle(
                            color: _getPriorityColor(widget.task.priority),
                            fontSize: 9, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12), 
              
              // Body
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white.withOpacity(0.5) : Colors.white,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.task.description ?? "No description",
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, 
                      color: Colors.grey,
                      height: 1.4
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12), 
              
              // Footer
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Creator Info (Left)
                   Expanded(
                     flex: 2,
                     child: Row(
                       children: [
                          const Text("BY:", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.task.createdBy == user?.id ? 'Me' : (widget.task.creatorName ?? 'Unknown'),
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                       ],
                     ),
                   ),

                   // Reviewers (Center/Right)
                   if (widget.task.reviewers.isNotEmpty)
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < widget.task.reviewers.length && i < 2; i++)
                                  Align(
                                    widthFactor: 0.6,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: AppColors.surface,
                                      child: CircleAvatar(
                                        radius: 8,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        child: Text(
                                          widget.task.reviewers[i].fullName.isNotEmpty 
                                              ? widget.task.reviewers[i].fullName[0].toUpperCase() 
                                              : '?',
                                          style: const TextStyle(fontSize: 7, color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (widget.task.reviewers.length > 2)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: AppColors.surfaceElevated,
                                      child: Text(
                                        '+${widget.task.reviewers.length - 2}',
                                        style: const TextStyle(fontSize: 7, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),

                   // Assignee Avatar (Right)
                   if (widget.task.assignedTo != null)
                     Expanded( 
                       flex: 2,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           const Text("TO: ", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                           const SizedBox(width: 4),
                           CircleAvatar(
                             radius: 8,
                             backgroundColor: AppColors.surfaceElevated,
                             child: Text(
                               _getInitials(widget.task.assigneeName ?? widget.task.assigneeEmail),
                               style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                           ),
                           const SizedBox(width: 4),
                           Flexible(
                             child: Text(
                               widget.task.assignedTo == user?.id ? 'Me' : (widget.task.assigneeName ?? widget.task.assigneeEmail ?? 'Unknown'),
                               style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                     ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (widget.index * 50).ms).fade().scale();
  }
}
