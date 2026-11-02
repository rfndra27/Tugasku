import 'package:cloud_firestore/cloud_firestore.dart';

class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? assignedToName;
  final String? assignedToPhone; // normalized 628xxx
  final DateTime? dueDate;
  final int orderIndex;

  SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.assignedToName,
    this.assignedToPhone,
    this.dueDate,
    this.orderIndex = 0,
  });

  SubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    String? assignedToName,
    String? assignedToPhone,
    DateTime? dueDate,
    int? orderIndex,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToPhone: assignedToPhone ?? this.assignedToPhone,
      dueDate: dueDate ?? this.dueDate,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'assigned_to_name': assignedToName,
      'assigned_to_phone': assignedToPhone,
      'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'order_index': orderIndex,
    };
  }

  factory SubtaskModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SubtaskModel(
      id: docId ?? json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      completedAt: parseDateTime(json['completed_at']),
      assignedToName: json['assigned_to_name']?.toString(),
      assignedToPhone: json['assigned_to_phone']?.toString(),
      dueDate: parseDateTime(json['due_date']),
      orderIndex: (json['order_index'] is num) ? (json['order_index'] as num).toInt() : 0,
    );
  }

  factory SubtaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SubtaskModel.fromJson(data, docId: doc.id);
  }
}

