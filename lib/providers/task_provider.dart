import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task_model.dart';
import 'package:dio/dio.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/tasks');
      final List data = response.data;
      _tasks = data.map((json) => Task.fromJson(json)).toList();
      
      // Sync notifications for all tasks (optional but good for consistency)
      _syncNotifications();
    } catch (e) {
      // Handle error cleanly or rethrow
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task> createTask(Map<String, dynamic> taskData, [String? filePath]) async {
     try {
       dynamic data;
       if (filePath != null) {
         data = FormData.fromMap({
           ...taskData,
           'attachment': await MultipartFile.fromFile(filePath),
         });
       } else {
         data = taskData;
       }

       final response = await _apiService.dio.post('/tasks', data: data);
       final newTask = Task.fromJson(response.data);
       await fetchTasks(); // Refresh list
       
       // Schedule Notification if due date exists
       if (newTask.dueBelow != null) {
         await NotificationService().scheduleTaskReminder(newTask);
       }
       
       return newTask;
     } catch (e) {
       rethrow;
     }
  }

  Future<void> updateTask({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    String? assignedToEmail,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (dueDate != null) data['due_datetime'] = dueDate.toIso8601String();
      if (priority != null) data['priority'] = priority;
      if (status != null) data['status'] = status;
      if (assignedToEmail != null && assignedToEmail.isNotEmpty) {
        data['assignedToEmail'] = assignedToEmail;
      }

      await _apiService.dio.patch('/tasks/$id', data: data);
      
      // Optimistic update or refresh
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
         await fetchTasks(); 
         
         // Update Notification
         final updatedTask = _tasks.firstWhere((t) => t.id == id);
         if (updatedTask.dueBelow != null) {
           await NotificationService().scheduleTaskReminder(updatedTask);
         } else {
           await NotificationService().cancelTaskReminder(id);
         }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _apiService.dio.delete('/tasks/$id');
      _tasks.removeWhere((t) => t.id == id);
      
      // Cancel Notification
      await NotificationService().cancelTaskReminder(id);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReviewer(int taskId, String email) async {
    try {
      await _apiService.dio.post('/tasks/$taskId/reviewers', data: {'email': email});
       await fetchTasks();
       notifyListeners(); 
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNotified(int taskId) async {
    try {
      await _apiService.dio.post('/tasks/$taskId/notified');
      // No state change needed really for UI unless we show "Last Notified"
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncNotifications() async {
    for (var task in _tasks) {
      if (task.dueBelow != null && task.status != 'Completed') {
        await NotificationService().scheduleTaskReminder(task);
      }
    }
  }
}
