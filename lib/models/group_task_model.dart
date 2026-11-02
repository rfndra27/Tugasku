import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String id;
  final String projectId;
  final String name;
  final String phone; // formatted as 628xxx
  final String role; // 'leader' | 'member'
  final DateTime joinedAt;

  GroupMemberModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.phone,
    this.role = 'member',
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  bool get isLeader => role.toLowerCase() == 'leader';

  GroupMemberModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? phone,
    String? role,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'phone': phone,
      'role': role,
      'joined_at': Timestamp.fromDate(joinedAt),
    };
  }

  factory GroupMemberModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GroupMemberModel(
      id: docId ?? json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Anggota',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAt: parseDate(json['joined_at']),
    );
  }

  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return GroupMemberModel.fromJson(data, docId: doc.id);
  }
}

class GroupProjectModel {
  final String id;
  final String userId;
  final String title;
  final String courseName;
  final String inviteCode;
  final DateTime createdAt;
  final List<GroupMemberModel> members;

  GroupProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.courseName,
    required this.inviteCode,
    DateTime? createdAt,
    this.members = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  int get memberCount => members.length;

  GroupProjectModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? courseName,
    String? inviteCode,
    DateTime? createdAt,
    List<GroupMemberModel>? members,
  }) {
    return GroupProjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      courseName: courseName ?? this.courseName,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'course_name': courseName,
      'invite_code': inviteCode,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupProjectModel.fromJson(Map<String, dynamic> json, {String? docId, List<GroupMemberModel>? members}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GroupProjectModel(
      id: docId ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tugas Kelompok',
      courseName: json['course_name']?.toString() ?? 'Mata Kuliah',
      inviteCode: json['invite_code']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      members: members ?? const [],
    );
  }

  factory GroupProjectModel.fromFirestore(DocumentSnapshot doc, {List<GroupMemberModel>? members}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return GroupProjectModel.fromJson(data, docId: doc.id, members: members);
  }
}

