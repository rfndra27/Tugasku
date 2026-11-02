import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/priority_calculator.dart';
import 'subtask_model.dart';

class TaskModel {
  final String id;
  final String userId;
  final String? courseId;
  final String courseName;
  final String title;
  final String description;
  final DateTime deadline;
  final double weightPercentage;
  final double priorityScore;
  final bool isCompleted;
  final DateTime? completedAt;
  final String source; // manual, ai_smart_input, elearning_ical
  final String? externalUid;
  final bool isGroupTask;
  final List<SubtaskModel> subtasks;

  TaskModel({
    required this.id,
    required this.userId,
    this.courseId,
    required this.courseName,
    required this.title,
    this.description = '',
    required this.deadline,
    this.weightPercentage = 10.0,
    double? priorityScore,
    this.isCompleted = false,
    this.completedAt,
    this.source = 'manual',
    this.externalUid,
    this.isGroupTask = false,
    this.subtasks = const [],
  }) : priorityScore = priorityScore ??
            PriorityCalculator.calculatePriority(
              deadline: deadline,
              weightPercentage: weightPercentage,
            );

  int get totalSubtasks => subtasks.length;
  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;
  double get progressPercentage {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    return completedSubtasks / totalSubtasks;
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? courseName,
    String? title,
    String? description,
    DateTime? deadline,
    double? weightPercentage,
    double? priorityScore,
    bool? isCompleted,
    DateTime? completedAt,
    String? source,
    String? externalUid,
    bool? isGroupTask,
    List<SubtaskModel>? subtasks,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      priorityScore: priorityScore ?? this.priorityScore,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      source: source ?? this.source,
      externalUid: externalUid ?? this.externalUid,
      isGroupTask: isGroupTask ?? this.isGroupTask,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'course_name': courseName,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'weight_percentage': weightPercentage,
      'priority_score': priorityScore,
      'is_completed': isCompleted,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'source': source,
      'external_uid': externalUid,
      'is_group_task': isGroupTask,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json, {String? docId, List<SubtaskModel>? subtasks}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final parsedDeadline = parseDateTime(json['deadline']);
    final parsedWeight = (json['weight_percentage'] is num)
        ? (json['weight_percentage'] as num).toDouble()
        : 10.0;
    final parsedPriority = (json['priority_score'] is num)
        ? (json['priority_score'] as num).toDouble()
        : PriorityCalculator.calculatePriority(
            deadline: parsedDeadline,
            weightPercentage: parsedWeight,
          );

    return TaskModel(
      id: docId ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseId: json['course_id']?.toString(),
      courseName: json['course_name']?.toString() ?? 'Mata Kuliah',
      title: json['title']?.toString() ?? 'Tugas',
      description: json['description']?.toString() ?? '',
      deadline: parsedDeadline,
      weightPercentage: parsedWeight,
      priorityScore: parsedPriority,
      isCompleted: json['is_completed'] == true,
      completedAt: parseNullableDateTime(json['completed_at']),
      source: json['source']?.toString() ?? 'manual',
      externalUid: json['external_uid']?.toString(),
      isGroupTask: json['is_group_task'] == true,
      subtasks: subtasks ?? const [],
    );
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc, {List<SubtaskModel>? subtasks}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TaskModel.fromJson(data, docId: doc.id, subtasks: subtasks);
  }
}

