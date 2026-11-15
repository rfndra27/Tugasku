import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class UserProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String university;
  final String nim;
  final String major;
  final String semester;
  final String phone;
  final String bio;
  final int avatarColor;
  final String? photoData; // base64-encoded profile picture (PNG)
  final bool isPremium;
  final DateTime? premiumExpiry;
  final int currentStreak;
  final int bestStreak;
  final String? lastCompletedDate; // format YYYY-MM-DD
  final int aiUsageCount;
  final DateTime? aiUsageResetDate;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.university = '',
    this.nim = '',
    this.major = '',
    this.semester = '',
    this.phone = '',
    this.bio = '',
    this.avatarColor = 0xFF6B8E78,
    this.photoData,
    this.isPremium = false,
    this.premiumExpiry,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
    this.aiUsageCount = 0,
    this.aiUsageResetDate,
  });

  int get remainingAiQuota {
    if (isPremium) return -1; // Unlimited
    final remaining = AppConstants.freeAiMonthlyQuota - aiUsageCount;
    return remaining > 0 ? remaining : 0;
  }

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? university,
    String? nim,
    String? major,
    String? semester,
    String? phone,
    String? bio,
    int? avatarColor,
    String? photoData,
    bool? isPremium,
    DateTime? premiumExpiry,
    int? currentStreak,
    int? bestStreak,
    String? lastCompletedDate,
    int? aiUsageCount,
    DateTime? aiUsageResetDate,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      nim: nim ?? this.nim,
      major: major ?? this.major,
      semester: semester ?? this.semester,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarColor: avatarColor ?? this.avatarColor,
      photoData: photoData ?? this.photoData,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      aiUsageCount: aiUsageCount ?? this.aiUsageCount,
      aiUsageResetDate: aiUsageResetDate ?? this.aiUsageResetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'university': university,
      'nim': nim,
      'major': major,
      'semester': semester,
      'phone': phone,
      'bio': bio,
      'avatar_color': avatarColor,
      'photo_data': photoData,
      'is_premium': isPremium,
      'premium_expiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_completed_date': lastCompletedDate,
      'ai_usage_count': aiUsageCount,
      'ai_usage_reset_date': aiUsageResetDate != null ? Timestamp.fromDate(aiUsageResetDate!) : null,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserProfileModel(
      id: docId ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Mahasiswa',
      university: json['university']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      major: json['major']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      avatarColor: (json['avatar_color'] is num) ? (json['avatar_color'] as num).toInt() : 0xFF6B8E78,
      photoData: json['photo_data']?.toString(),
      isPremium: json['is_premium'] == true,
      premiumExpiry: parseDate(json['premium_expiry']),
      currentStreak: (json['current_streak'] is num) ? (json['current_streak'] as num).toInt() : 0,
      bestStreak: (json['best_streak'] is num) ? (json['best_streak'] as num).toInt() : 0,
      lastCompletedDate: json['last_completed_date']?.toString(),
      aiUsageCount: (json['ai_usage_count'] is num) ? (json['ai_usage_count'] as num).toInt() : 0,
      aiUsageResetDate: parseDate(json['ai_usage_reset_date']),
    );
  }

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserProfileModel.fromJson(data, docId: doc.id);
  }
}

