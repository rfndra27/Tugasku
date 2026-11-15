import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class GroupMemberModel {
  final String id;
  final String projectId;
  final String name;
  final String phone;
  final String role;
  final String roleLabel;
  final String email;
  final String? memberUserId;
  final DateTime joinedAt;

  GroupMemberModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.phone,
    this.role = 'member',
    this.roleLabel = '',
    this.email = '',
    this.memberUserId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  bool get isLeader => role.toLowerCase() == 'leader';

  GroupMemberModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? phone,
    String? role,
    String? roleLabel,
    String? email,
    String? memberUserId,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      email: email ?? this.email,
      memberUserId: memberUserId ?? this.memberUserId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'name': name,
        'phone': phone,
        'role': role,
        'role_label': roleLabel,
        'email': email,
        'member_user_id': memberUserId,
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
      roleLabel: json['role_label']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      memberUserId: json['member_user_id']?.toString(),
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

class GroupInvitationModel {
  final String id;
  final String recipientUserId;
  final String recipientEmail;
  final String projectId;
  final String projectTitle;
  final String courseName;
  final String inviteCode;
  final String senderName;
  final List<GroupMemberModel> members;
  final String status;

  GroupInvitationModel({
    required this.id,
    required this.recipientUserId,
    required this.recipientEmail,
    required this.projectId,
    required this.projectTitle,
    required this.courseName,
    required this.inviteCode,
    required this.senderName,
    required this.members,
    this.status = 'pending',
  });

  factory GroupInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final rawMembers = data['members'] is List ? data['members'] as List : const [];
    return GroupInvitationModel(
      id: doc.id,
      recipientUserId: data['recipient_user_id']?.toString() ?? '',
      recipientEmail: data['recipient_email']?.toString() ?? '',
      projectId: data['project_id']?.toString() ?? '',
      projectTitle: data['project_title']?.toString() ?? 'Tugas Kelompok',
      courseName: data['course_name']?.toString() ?? 'Mata Kuliah',
      inviteCode: data['invite_code']?.toString() ?? '',
      senderName: data['sender_name']?.toString() ?? 'Teman',
      status: data['status']?.toString() ?? 'pending',
      members: rawMembers.whereType<Map>().map((m) => GroupMemberModel.fromJson(Map<String, dynamic>.from(m))).toList(),
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

  /// Generates a short, collision-resistant invite code such as "GRP-8F2A9C".
  static String generateInviteCode() {
    final uuid = Uuid().v4().replaceAll('-', '').toUpperCase();
    return 'GRP-${uuid.substring(0, 6)}';
  }

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
    String? id,
    String? projectId,
    String? title,
    String? type,
    int? priority,
    String? ownerName,
    String? ownerPhone,
    int? progressPercent,
    DeliverableStatus? status,
  }) {
    return GroupDeliverableModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
    );
  }

  static DeliverableStatus statusFromValue(dynamic value) {
    final raw = value?.toString() ?? '';
    switch (raw) {
      case 'completed':
        return DeliverableStatus.completed;
      case 'inProgress':
      case 'in_progress':
        return DeliverableStatus.inProgress;
      default:
        return DeliverableStatus.pending;
    }
  }

  static String statusToValue(DeliverableStatus status) {
    switch (status) {
      case DeliverableStatus.completed:
        return 'completed';
      case DeliverableStatus.inProgress:
        return 'in_progress';
      case DeliverableStatus.pending:
        return 'pending';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'type': type,
        'priority': priority,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'progress_percent': progressPercent,
        'status': statusToValue(status),
      };

  factory GroupDeliverableModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return GroupDeliverableModel(
      id: docId ?? json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Deliverable',
      type: json['type']?.toString() ?? 'Planning',
      priority: json['priority'] is num ? (json['priority'] as num).toInt() : 3,
      ownerName: json['owner_name']?.toString() ?? '',
      ownerPhone: json['owner_phone']?.toString() ?? '',
      progressPercent: json['progress_percent'] is num ? (json['progress_percent'] as num).toInt() : 0,
      status: statusFromValue(json['status']),
    );
  }

  factory GroupDeliverableModel.fromFirestore(DocumentSnapshot doc) {
    return GroupDeliverableModel.fromJson(
      (doc.data() as Map<String, dynamic>?) ?? {},
      docId: doc.id,
    );
  }
}

class GroupActivityModel {
  final String id;
  final String actorName;
  final String description;
  final DateTime createdAt;

  GroupActivityModel({
    this.id = '',
    required this.actorName,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor_name': actorName,
        'description': description,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory GroupActivityModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final value = json['created_at'];
    final createdAt = value is Timestamp
        ? value.toDate()
        : value is DateTime
            ? value
            : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return GroupActivityModel(
      id: docId ?? json['id']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? 'Anggota',
      description: json['description']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  factory GroupActivityModel.fromFirestore(DocumentSnapshot doc) {
    return GroupActivityModel.fromJson(
      (doc.data() as Map<String, dynamic>?) ?? {},
      docId: doc.id,
    );
  }
}
