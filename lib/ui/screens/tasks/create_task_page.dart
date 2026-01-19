import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../../providers/task_provider.dart';
import '../../components/app_text_field.dart';
import '../../components/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../layout/responsive_builder.dart';
import '../../widgets/deep_background.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _priority = 'Medium';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _filePath;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      theme: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: AppColors.surfaceElevated,
        ),
      ),
    );
    if (picked != null) {
      debugPrint('Date picker - Selected: $picked');
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      theme: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: AppColors.surfaceElevated,
        ),
      ),
    );
    if (picked != null) {
      debugPrint('Time picker - Selected: $picked (hour: ${picked.hour}, minute: ${picked.minute})');
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      if (result.files.single.path != null) {
        setState(() => _filePath = result.files.single.path);
      }
    }
  }

  void _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    DateTime? dueDateTime;
    if (_selectedDate != null) {
        debugPrint('Selected Date: $_selectedDate');
        debugPrint('Selected Time: $_selectedTime');
        
        dueDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime?.hour ?? 0,
          _selectedTime?.minute ?? 0,
        );
        
        debugPrint('Combined DateTime: $dueDateTime');
    }

    try {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _priority,
        'priority': _priority,
        'due_datetime': dueDateTime?.toIso8601String(),
        if (_assignedToController.text.isNotEmpty) 'assignedToEmail': _assignedToController.text.trim(),
      };

      await context.read<TaskProvider>().createTask(taskData, _filePath);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task Created!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for DeepBackground
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('New Task'),
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: DeepBackground(
        child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   FadeInDown(
                     child: Text(
                       'Create New Task',
                       style: AppTypography.textTheme.headlineLarge,
                     ),
                   ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    child: AppTextField(
                      label: 'Task Title',
                      hint: 'e.g. Redesign Landing Page',
                      controller: _titleController,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: AppTextField(
                      label: 'Description',
                      hint: 'Add some details...',
                      controller: _descController,
                      maxLines: 3,
                    ),
                  ),
                   const SizedBox(height: 24),
                   FadeInUp(
                     delay: const Duration(milliseconds: 200),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Priority', style: AppTypography.textTheme.labelMedium),
                         const SizedBox(height: 8),
                         DropdownButtonFormField<String>(
                           value: _priority,
                           dropdownColor: AppColors.surfaceElevated,
                           style: AppTypography.textTheme.bodyMedium,
                           decoration: InputDecoration(
                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                           ),
                           items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(
                             value: p,
                             child: Text(p),
                           )).toList(),
                           onChanged: (val) => setState(() => _priority = val!),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   FadeInUp(
                     delay: const Duration(milliseconds: 250),
                     child: AppTextField(
                       label: 'Assign To (Email)',
                       hint: 'colleague@example.com (Optional)',
                       controller: _assignedToController,
                       keyboardType: TextInputType.emailAddress,
                     ),
                   ),
                   const SizedBox(height: 24),
                   FadeInUp(
                     delay: const Duration(milliseconds: 300),
                     child: Row(
                       children: [
                         Expanded(
                           child: AppButton(
                             label: _selectedDate == null ? 'Pick Date' : DateFormat('MMM d, y').format(_selectedDate!),
                             icon: Icons.calendar_today,
                             variant: AppButtonVariant.outline,
                             onPressed: _pickDate,
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: AppButton(
                             label: _selectedTime == null ? 'Pick Time' : _selectedTime!.format(context),
                             icon: Icons.access_time,
                             variant: AppButtonVariant.outline,
                             onPressed: _pickTime,
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   FadeInUp(
                     delay: const Duration(milliseconds: 400),
                     child: AppButton(
                       label: _filePath == null ? 'Attach File' : 'File Selected',
                       icon: Icons.attach_file,
                       variant: AppButtonVariant.outline,
                       onPressed: _pickFile,
                      //  color: _filePath != null ? AppColors.primary : null,
                     ),
                   ),
                   const SizedBox(height: 48),
                   FadeInUp(
                     delay: const Duration(milliseconds: 500),
                     child: AppButton(
                       label: 'Create Task',
                       onPressed: _createTask,
                       isLoading: _isLoading,
                       size: AppButtonSize.large,
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
