import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';

class TaskModal extends StatefulWidget {
  final Task? task; // If null, we are in Create mode
  final bool isViewing; // If true, start in View mode (only if task != null)

  const TaskModal({
    super.key,
    this.task,
    this.isViewing = false,
  });

  static Future<void> show(BuildContext context, {Task? task, bool isViewing = false}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Darker barrier since we removed blur
      builder: (context) => TaskModal(task: task, isViewing: isViewing),
    );
  }

  @override
  State<TaskModal> createState() => _TaskModalState();
}

class _TaskModalState extends State<TaskModal> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  // Note: Assignee is now handled via UI selection, but we keep controller for backward compat if needed or search
  
  DateTime _selectedDate = DateTime.now();
  String _priority = 'Medium';
  String _status = 'Open';
  bool _isLoading = false;

  bool _isCreator = false;
  bool _isAssignee = false;
  bool _canEditDetails = false;
  bool _isEditing = false; 
  bool _isTitleFocused = false; 
  String? _assignedToEmail; 
  late List<String> _reviewerEmails; 

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    
    // RBAC
    _isCreator = widget.task?.createdBy == user?.id || widget.task == null; // Creator if new or matches ID
    _isAssignee = widget.task?.assignedTo == user?.id; // Int ID check
    
    // Edit Permission: Strictly Creator only for details (Title, Prop, etc)
    // If new task, of course we can edit.
    _canEditDetails = widget.task == null || _isCreator;
    _isEditing = widget.task == null; // Start in Edit mode for new tasks

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.dueBelow ?? DateTime.now();
    _priority = widget.task?.priority ?? 'Medium';
    _status = widget.task?.status ?? 'Open';
    _reviewerEmails = []; 
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final provider = context.read<TaskProvider>();
      
      if (widget.task == null) {
        // Create
        final newTask = await provider.createTask({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'due_datetime': _selectedDate.toIso8601String(),
          'priority': _priority,
          'status': _status, 
          'assignedToEmail': _assignedToEmail,
        });

        // Add Reviewers sequentially for new task
        for (final email in _reviewerEmails) {
           await provider.addReviewer(newTask.id, email);
        }
      } else {
        // Update (Creator only for details)
        if (_isCreator) {
            await provider.updateTask(
              id: widget.task!.id,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              dueDate: _selectedDate,
              priority: _priority,
              status: _status,
            );
        } else if (_isAssignee) {
           // Assignee can only change status, but _saveTask usually implies full save.
           // However, status changes are usually immediate in the strip.
           // If we are here, maybe just save description? But Assignee can't edit desc.
           // So for assignee, this might just be a no-op or status sync.
           await provider.updateTask(id: widget.task!.id, status: _status);
        }
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
     setState(() => _isLoading = true);
     try {
       await context.read<TaskProvider>().deleteTask(widget.task!.id);
       if (mounted) Navigator.pop(context);
     } catch (e) {
       if (mounted) {
         setState(() => _isLoading = false);
         _showError(e.toString());
       }
     }
  }

  Future<void> _updateStatus(String newStatus) async {
    // Immediate Update for UX
    setState(() {
      _status = newStatus;
      _isLoading = true;
    });
    
    // If creating, we just hold the state. If existing, we push update.
    if (widget.task != null) {
      try {
        await context.read<TaskProvider>().updateTask(id: widget.task!.id, status: newStatus);
        // Success feedback?
      } catch (e) {
        _showError(e.toString());
        // Revert?
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  // --- UI Builders ---

  void _showAddUserDialog({bool isReviewer = false}) {
     final emailCtrl = TextEditingController();
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppColors.surface,
         title: Text(isReviewer ? "Add Reviewer" : "Assign User", style: const TextStyle(color: Colors.white)),
         // Wrapppin in Column min to fix height issue
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             AppTextField(label: "Email", controller: emailCtrl, hint: "Enter email"),
           ],
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              TextButton(onPressed: () async {
               if (emailCtrl.text.isEmpty) return;
               
               if (widget.task == null) {
                  // Creation Mode: Update local state
                  setState(() {
                    if (isReviewer) {
                      if (!_reviewerEmails.contains(emailCtrl.text.trim())) {
                        _reviewerEmails.add(emailCtrl.text.trim());
                      }
                    } else {
                      _assignedToEmail = emailCtrl.text.trim();
                    }
                  });
                  Navigator.pop(ctx);
                  return;
               }

               try {
                 if (isReviewer) {
                    await context.read<TaskProvider>().addReviewer(widget.task!.id, emailCtrl.text.trim());
                 } else {
                    // Reassign Logic (Update Task)
                    await context.read<TaskProvider>().updateTask(id: widget.task!.id, assignedToEmail: emailCtrl.text.trim());
                 }
                 if (ctx.mounted) Navigator.pop(ctx);
               } catch (e) {
                 // error
               }
            }, child: const Text("Add")),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    // If existing task, watch for updates
    Task? t;
    if (widget.task != null) {
      try {
        t = context.watch<TaskProvider>().tasks.firstWhere((element) => element.id == widget.task!.id);
      } catch (_) {
        t = widget.task;
      }
    }
    
    // If t is null (create mode) or found
    final isNew = t == null;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Center(
      child: Container(
        width: isMobile ? size.width * 0.92 : 600, 
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          // Reduced opacity for glass effect
          color: const Color(0xFF0A0A0A).withOpacity(0.85), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
               // Header
               _buildHeader(t),
               
               // Scrollable Body
               Expanded(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                   child: Form(
                     key: _formKey,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const SizedBox(height: 10),
                          
                          // Title
                          Focus(
                            onFocusChange: (focused) => setState(() => _isTitleFocused = focused),
                            child: TextFormField(
                               controller: _titleController,
                               enabled: _isEditing && _isCreator, // Respect editing and RBAC
                               style: AppTypography.textTheme.headlineMedium?.copyWith(
                                 color: Colors.white, fontWeight: FontWeight.bold
                               ),
                               decoration: InputDecoration(
                                 // Explicitly removing borders when not focused
                                 border: InputBorder.none,
                                 enabledBorder: InputBorder.none,
                                 focusedBorder: OutlineInputBorder(
                                   borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 filled: _isTitleFocused,
                                 fillColor: _isTitleFocused ? Colors.white.withOpacity(0.05) : Colors.transparent,
                                 hintText: "Task Title",
                                 hintStyle: const TextStyle(color: Colors.white24),
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                               ),
                               validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Status Strip (Hidden for new tasks)
                          if (!isNew)
                             _buildStatusStrip(t?.status ?? _status),
                          
                          if (!isNew)
                             const SizedBox(height: 24),
                          
                          // Priority & Date Grid
                          isMobile 
                          ? Column(
                              children: [
                                _buildPropertyCard(
                                  label: "PRIORITY",
                                  value: _priority,
                                  icon: Icons.flag,
                                  color: _getPriorityColor(_priority),
                                  onTap: (_isEditing && _isCreator) ? () => _showPriorityPicker() : null,
                                ),
                                const SizedBox(height: 16),
                                _buildPropertyCard(
                                  label: "DUE DATE",
                                  value: DateFormat("MMM d, yyyy HH:mm").format(_selectedDate),
                                  icon: Icons.calendar_today,
                                  onTap: (_isEditing && _isCreator) ? () => _showDatePicker() : null,
                                ),
                              ],
                            )
                          : Row(
                            children: [
                               Expanded(child: _buildPropertyCard(
                                 label: "PRIORITY",
                                 value: _priority,
                                 icon: Icons.flag,
                                 color: _getPriorityColor(_priority),
                                 onTap: (_isEditing && _isCreator) ? () => _showPriorityPicker() : null,
                               )),
                               const SizedBox(width: 16),
                               Expanded(child: _buildPropertyCard(
                                 label: "DUE DATE",
                                 value: DateFormat("MMM d, yyyy HH:mm").format(_selectedDate),
                                 icon: Icons.calendar_today,
                                 onTap: (_isEditing && _isCreator) ? () => _showDatePicker() : null,
                               )),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Description
                          Text("DESCRIPTION", style: _labelStyle()),
                          const SizedBox(height: 8),
                          TextFormField(
                             controller: _descController,
                             enabled: _isEditing && _isCreator, // Respect editing and RBAC
                             maxLines: 5,
                             style: const TextStyle(color: Colors.white70, height: 1.5),
                             decoration: InputDecoration(
                               filled: true,
                               fillColor: AppColors.surfaceElevated.withOpacity(0.5),
                               hintText: "Add a more detailed description...",
                               hintStyle: const TextStyle(color: Colors.white24),
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                               ),
                               enabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                               ),
                               focusedBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                               ),
                               contentPadding: const EdgeInsets.all(20), // Increased padding for breathing room
                             ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Assignee Section
                          _buildPeopleSection(
                             title: "ASSIGNED TO",
                              // If creating, show tracked email. If existing, show t.assignee
                             users: isNew 
                               ? (_assignedToEmail != null ? [_UserStub(_assignedToEmail, "Assignee")] : <_UserStub>[])
                               : (((t?.assigneeName != null || t?.assigneeEmail != null)) 
                                   ? [_UserStub(t?.assigneeName ?? t?.assigneeEmail, "Assignee")]
                                   : <_UserStub>[]),
                             onAdd: (_isEditing && _isCreator) ? () => _showAddUserDialog(isReviewer: false) : null,
                             emptyText: "No assignee",
                          ),

                          const SizedBox(height: 24),
                          
                          // Reviewers Section
                          _buildPeopleSection(
                             title: "REVIEWERS",
                             users: isNew 
                               ? (_reviewerEmails ?? <String>[]).map((e) => _UserStub(e, "Reviewer")).toList()
                               : (t?.reviewers ?? <Reviewer>[]).map((r) => _UserStub((r.fullName ?? "").isNotEmpty ? r.fullName : r.email, "Reviewer")).toList(),
                             onAdd: (_isEditing && (_isCreator || _isAssignee)) ? () => _showAddUserDialog(isReviewer: true) : null,
                             emptyText: "No reviewers",
                          ),

                       ],
                     ),
                   ),
                 ),
               ),
               
               // Footer
               _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Task? t) {
     return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
             // Removed "Projects >" breadcrumb as per user request
             Text(t != null ? "TASK-${t.id}" : "NEW-TASK", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             
             const Spacer(),
             
             if (!_isEditing && (_isCreator || _isAssignee))
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: "Edit Task",
                ),

             IconButton(
               icon: const Icon(Icons.close, color: Colors.white54),
               onPressed: () => Navigator.pop(context),
             ),
          ],
        ),
     );
  }
  
  Widget _buildStatusStrip(String currentStatus) {
     final statuses = ['Open', 'Started', 'In Progress', 'Completed']; 
     String mapToUi(String s) => s == 'Work In Progress' ? 'In Progress' : s;
     String mapToLogic(String s) => s == 'In Progress' ? 'Work In Progress' : s;
     
     final uiStatus = mapToUi(currentStatus);
     final isCompleted = uiStatus == 'Completed';

     if (isCompleted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("STATUS", style: _labelStyle()),
                 if (widget.task != null) 
                    Text("Top Job!", style: TextStyle(fontSize: 10, color: AppColors.success)),
               ],
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
               decoration: BoxDecoration(
                 color: AppColors.surfaceElevated.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: AppColors.success.withOpacity(0.3)),
               ),
               child: Row(
                 children: [
                   const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                   const SizedBox(width: 12),
                   const Text("COMPLETED", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   const Spacer(),
                   
                   // Reopen Action (Creator Only)
                   if (_isCreator || widget.task == null)
                      TextButton.icon(
                        onPressed: () => _updateStatus('Open'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Reopen"),
                      )
                 ],
               ),
             ),
          ],
        );
     }
     
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("STATUS", style: _labelStyle()),
              if (widget.task != null) 
                 Text("Updated just now", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
           Container(
              height: 48, // Slightly taller for better touch
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.6),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: statuses.map((s) {
                   final isActive = s == uiStatus;
                   final isLogicalActive = mapToUi(s) == uiStatus;
                   
                   final currentIndex = statuses.indexOf(uiStatus);
                   final targetIndex = statuses.indexOf(s);
                   
                   // Strict Forward Logic check: 
                   // Only Assignee can change status. 
                   // Can only move forward (targetIndex > currentIndex).
                   // Status strip is visible to everyone, but disabled for non-assignees/backward moves.
                   final isForward = targetIndex > currentIndex;
                   final isCreatorInitial = (_isCreator && widget.task == null); // Creator can set initial status
                   
                   final canInteract = _isEditing && ((_isAssignee && isForward) || isCreatorInitial);
                   
                   // Visual feedback for disabled actions? Maybe dimmer?
                   final opacity = (targetIndex < currentIndex || !_isEditing) ? 0.3 : 1.0; 

                   return Expanded(
                     child: GestureDetector(
                       onTap: canInteract ? () => _updateStatus(mapToLogic(s)) : null,
                       child: AnimatedOpacity(
                         duration: 200.ms,
                         opacity: opacity,
                         child: AnimatedContainer(
                           duration: 250.ms,
                           curve: Curves.easeOut,
                           decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF333333) : Colors.transparent, 
                              borderRadius: BorderRadius.circular(6),
                              gradient: isActive ? const LinearGradient(
                                colors: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter
                              ) : null,
                              boxShadow: isActive ? [
                                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                              ] : null,
                           ),
                           alignment: Alignment.center,
                           child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, 
                                  color: isActive ? 
                                    (s=='Completed'?AppColors.success : s=='In Progress'?Colors.blue : Colors.grey) 
                                    : Colors.white24),
                                const SizedBox(width: 6),
                                Text(s, style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.white : Colors.white54
                                )),
                              ],
                           ),
                         ),
                       ),
                     ),
                   );
                }).toList(),
              ),
           )
       ],
     );
  }
  
  Widget _buildPropertyCard({required String label, required String value, required IconData icon, Color? color, VoidCallback? onTap}) {
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(12),
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.8), // Slightly translucent
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text(label, style: _labelStyle()),
              const SizedBox(height: 12),
              Row(
                children: [
                   Icon(icon, size: 18, color: color ?? Colors.white70),
                   const SizedBox(width: 8),
                   Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   if (onTap != null) Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white24),
                ],
              ),
           ],
         ),
       ),
     );
  }
  
  Widget _buildPeopleSection({
    required String title, 
    required List<_UserStub> users, 
    required VoidCallback? onAdd, 
    required String emptyText
  }) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Text(title, style: _labelStyle()),
          const SizedBox(height: 12),
          // Removed container decoration/background to fix "height" and "opacity" complaints
          Row(
            children: [
               if (users.isEmpty)
                  Text(emptyText, style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic))
               else
                  ...(users ?? []).map((u) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Chip(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      avatar: CircleAvatar(
                        backgroundColor: AppColors.primary, 
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', 
                          style: const TextStyle(fontSize: 10, color: Colors.black)
                        ),
                      ),
                      label: Text(u.name, style: const TextStyle(color: Colors.white)),
                      side: BorderSide.none,
                    ),
                  )),
               
               const Spacer(),
               
               if (onAdd != null)
                  IconButton.filled(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
            ],
          )
       ],
     );
  }
  
  Widget _buildFooter() {
     if (!_isEditing) return const SizedBox.shrink(); // Hide footer when viewing

     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
           color: const Color(0xFF0F0F0F).withOpacity(0.8), // Translucent footer
           border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          children: [
             // Delete Button (Creator only)
             if (_isCreator && widget.task != null)
                TextButton.icon(
                  onPressed: _deleteTask,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                  label: const Text("Delete", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
             
             const Spacer(),
             
             TextButton(
               onPressed: () {
                 if (widget.task == null) {
                    Navigator.pop(context);
                 } else {
                    setState(() => _isEditing = false);
                 }
               },
               child: const Text("Cancel"),
             ),
             const SizedBox(width: 8),
             
             if (_isLoading)
               const CircularProgressIndicator()
             else
               ElevatedButton(
                 onPressed: _saveTask,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF6366F1), // Indigo/Purple accent
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
                 child: Text(widget.task == null ? "Create" : "Save"),
               ),
          ],
        ),
      );

  }
  
  TextStyle _labelStyle() => const TextStyle(color: Color(0xFF808080), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0);
  
  Color _getPriorityColor(String p) {
     switch(p.toLowerCase()) {
       case 'high': return AppColors.error;
       case 'medium': return AppColors.warning;
       case 'low': return AppColors.success;
       default: return Colors.white;
     }
  }
  
  void _showPriorityPicker() {
      // Simple dialog or menu
      // Implementation omitted for brevity to stick to layout, but logic exists
      showDialog(context: context, builder: (ctx) => SimpleDialog(
        title: const Text("Select Priority"),
        children: ['Low', 'Medium', 'High'].map((p) => SimpleDialogOption(
          onPressed: () { setState(() => _priority = p); Navigator.pop(ctx); },
          child: Text(p),
        )).toList(),
      ));
  }
  
  void _showDatePicker() async {
     final date = await showDatePicker(
       context: context, 
       initialDate: _selectedDate, 
       firstDate: DateTime.now(), 
       lastDate: DateTime.now().add(const Duration(days: 365))
     );
     if (date != null) {
        final time = await showTimePicker(
          context: context, 
          initialTime: TimeOfDay.fromDateTime(_selectedDate),
        );
        if (time != null) {
          setState(() {
            _selectedDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
     }
  }
}

class _UserStub {
  final String name;
  final String role;
  _UserStub(String? rawName, this.role) : name = (rawName != null && rawName.isNotEmpty) ? rawName : 'Unknown';
}
