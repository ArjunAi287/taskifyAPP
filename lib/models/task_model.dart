import 'dart:convert';

class Reviewer {
  final int id;
  final String email;
  final String fullName;

  Reviewer({required this.id, required this.email, required this.fullName});

  factory Reviewer.fromJson(Map<String, dynamic> json) {
    return Reviewer(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
    );
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? dueBelow;         // due_datetime from DB
  final int? assignedTo;
  final int? createdBy;

  // New Fields for UI
  final String? creatorName;
  final String? creatorEmail;
  final String? assigneeName;
  final String? assigneeEmail;

  final String? attachmentPath;
  final List<Reviewer> reviewers;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueBelow,
    this.assignedTo,
    this.createdBy,
    this.creatorName,
    this.creatorEmail,
    this.assigneeName,
    this.assigneeEmail,
    this.attachmentPath,
    this.reviewers = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? 'Untitled Task',
      description: json['description'],
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Open',
      dueBelow: json['due_datetime'] != null ? DateTime.parse(json['due_datetime']).toLocal() : null,
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      creatorName: json['creator_name'],
      creatorEmail: json['creator_email'],
      assigneeName: json['assignee_name'],
      assigneeEmail: json['assignee_email'],
      attachmentPath: json['attachment_path'],
      reviewers: _parseReviewers(json),
    );
  }

  static List<Reviewer> _parseReviewers(Map<String, dynamic> json) {
    try {
      if (json['reviewers'] != null && json['reviewers'] is List) {
        return (json['reviewers'] as List).map((i) => Reviewer.fromJson(i)).toList();
      } else if (json['reviewers_json'] != null) {
        final val = json['reviewers_json'];
        // It might be a string (JSON) or already parsed by some interceptor
        if (val is String) {
          if (val.isEmpty) return [];
          final List<dynamic> parsed = jsonDecode(val);
          return parsed.map((i) => Reviewer.fromJson(i)).toList();
        } else if (val is List) {
          return val.map((i) => Reviewer.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error parsing reviewers: $e');
      return [];
    }
  }
}
