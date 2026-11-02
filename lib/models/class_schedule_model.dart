import 'package:cloud_firestore/cloud_firestore.dart';

class ClassScheduleModel {
  final String id;
  final String userId;
  final String courseName;
  final int dayOfWeek; // 1 = Senin, 2 = Selasa, ..., 7 = Minggu
  final String startTime; // "HH:mm" e.g. "08:00"
  final String endTime; // "HH:mm" e.g. "09:40"
  final String room;

  ClassScheduleModel({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Hari';
    }
  }

  int get startTotalMinutes {
    final parts = startTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return hour * 60 + minute;
    }
    return 0;
  }

  int get endTotalMinutes {
    final parts = endTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return hour * 60 + minute;
    }
    return 0;
  }

  ClassScheduleModel copyWith({
    String? id,
    String? userId,
    String? courseName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return ClassScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_name': courseName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ClassScheduleModel(
      id: docId ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      dayOfWeek: (json['day_of_week'] is num) ? (json['day_of_week'] as num).toInt() : 1,
      startTime: json['start_time']?.toString() ?? '08:00',
      endTime: json['end_time']?.toString() ?? '10:00',
      room: json['room']?.toString() ?? '',
    );
  }

  factory ClassScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ClassScheduleModel.fromJson(data, docId: doc.id);
  }
}

