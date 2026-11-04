import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String id;
  final String projectId;
  final String name;
  final String phone;
  final String role;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'name': name,
        'phone': phone,
        'role': role,
        'joined_at': Timestamp.fromDate(joinedAt),
      };

  factory GroupMemberModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final value = json['joined_at'];
    final joinedAt = value is Timestamp
        ? value.toDate()
        : value is DateTime
            ? value
            : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return GroupMemberModel(
      id: docId ?? json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Anggota',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAt: joinedAt,
    );
  }

  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    return GroupMemberModel.fromJson(
      (doc.data() as Map<String, dynamic>?) ?? {},
      docId: doc.id,
    );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'course_name': courseName,
        'invite_code': inviteCode,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory GroupProjectModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
    List<GroupMemberModel>? members,
  }) {
    final value = json['created_at'];
    final createdAt = value is Timestamp
        ? value.toDate()
        : value is DateTime
            ? value
            : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return GroupProjectModel(
      id: docId ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tugas Kelompok',
      courseName: json['course_name']?.toString() ?? 'Mata Kuliah',
      inviteCode: json['invite_code']?.toString() ?? '',
      createdAt: createdAt,
      members: members ?? const [],
    );
  }

  factory GroupProjectModel.fromFirestore(
    DocumentSnapshot doc, {
    List<GroupMemberModel>? members,
  }) {
    return GroupProjectModel.fromJson(
      (doc.data() as Map<String, dynamic>?) ?? {},
      docId: doc.id,
      members: members,
    );
  }
}

enum DeliverableStatus { pending, inProgress, completed }

class GroupDeliverableModel {
  final String id;
  final String projectId;
  final String title;
  final String type;
  final int priority;
  final String ownerName;
  final String ownerPhone;
  final int progressPercent;
  final DeliverableStatus status;

  GroupDeliverableModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.type,
    required this.priority,
    required this.ownerName,
    required this.ownerPhone,
    required this.progressPercent,
    required this.status,
  });

  GroupDeliverableModel copyWith({
    int? progressPercent,
    DeliverableStatus? status,
  }) {
    return GroupDeliverableModel(
      id: id,
      projectId: projectId,
      title: title,
      type: type,
      priority: priority,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
    );
  }
}

class GroupActivityModel {
  final String actorName;
  final String description;
  final DateTime createdAt;

  GroupActivityModel({
    required this.actorName,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
