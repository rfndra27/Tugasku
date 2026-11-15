import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants.dart';
import '../core/priority_calculator.dart';
import '../models/class_schedule_model.dart';
import '../models/group_task_model.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';

class FirebaseService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final FirebaseFunctions? _customFunctions;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customFunctions = functions;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions => _customFunctions ?? FirebaseFunctions.instance;

  // Auth getters
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  String? get currentUserId {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      return Stream<User?>.value(null);
    }
  }

  // ----------------------------------------------------
  // AUTHENTICATION & PROFILE
  // ----------------------------------------------------
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String university,
    String nim = '',
    String phone = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(fullName);
      // Initialize profile document in profiles/{userId}
      final normalizedPhone = phone.isNotEmpty ? normalizePhone(phone) : '';
      await _firestore.collection('profiles').doc(user.uid).set({
        'id': user.uid,
        'email': email,
        'full_name': fullName,
        'university': university,
        'nim': nim,
        'major': '',
        'semester': '',
        'phone': normalizedPhone,
        'bio': '',
        'avatar_color': 0xFF6B8E78,
        'is_premium': false,
        'premium_expiry': null,
        'current_streak': 0,
        'best_streak': 0,
        'last_completed_date': null,
        'ai_usage_count': 0,
        'ai_usage_reset_date': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
      if (normalizedPhone.isNotEmpty) {
        await upsertPhoneLookup(phone: normalizedPhone, email: email, uid: user.uid);
      }
    }
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _ensureProfileExists(cred.user);
    if (cred.user != null) {
      await seedInitialCharterDataIfEmpty(cred.user!.uid);
    }
    return cred;
  }

  Future<UserCredential> signInWithFacebook() async {
    final provider = FacebookAuthProvider();
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _ensureProfileExists(cred.user);
    if (cred.user != null) {
      await seedInitialCharterDataIfEmpty(cred.user!.uid);
    }
    return cred;
  }

  Future<void> _ensureProfileExists(User? user) async {
    if (user == null) return;
    final docRef = _firestore.collection('profiles').doc(user.uid);
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'id': user.uid,
        'email': user.email ?? '',
        'full_name': (user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName! : 'Mahasiswa',
        'university': 'Politeknik Negeri Jakarta',
        'nim': '',
        'major': '',
        'semester': '',
        'phone': user.phoneNumber ?? '',
        'bio': '',
        'avatar_color': 0xFF6B8E78,
        'is_premium': false,
        'premium_expiry': null,
        'current_streak': 0,
        'best_streak': 0,
        'last_completed_date': null,
        'ai_usage_count': 0,
        'ai_usage_reset_date': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<UserProfileModel?> streamUserProfile(String userId) {
    return _firestore.collection('profiles').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  Future<UserProfileModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile(UserProfileModel profile) async {
    await _auth.currentUser?.updateDisplayName(profile.fullName);
    final docRef = _firestore.collection('profiles').doc(profile.id);
    final docSnap = await docRef.get();
    final editableData = {
      'id': profile.id,
      'email': profile.email,
      'full_name': profile.fullName,
      'university': profile.university,
      'nim': profile.nim,
      'major': profile.major,
      'semester': profile.semester,
      'phone': profile.phone,
      'bio': profile.bio,
      'avatar_color': profile.avatarColor,
    };

    if (docSnap.exists) {
      await docRef.update(editableData);
    } else {
      await docRef.set({
        ...editableData,
        'is_premium': false,
        'premium_expiry': null,
        'current_streak': 0,
        'best_streak': 0,
        'last_completed_date': null,
        'ai_usage_count': 0,
        'ai_usage_reset_date': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    if (profile.phone.isNotEmpty) {
      await upsertPhoneLookup(phone: profile.phone, email: profile.email, uid: profile.id);
    }
  }

  // ----------------------------------------------------
  // TASKS CRUD
  // ----------------------------------------------------
  Stream<List<TaskModel>> streamTasks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      // Auto-sort by priority score descending
      tasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      return tasks;
    });
  }

  Future<void> createTask(TaskModel task) async {
    final docRef = _firestore
        .collection('users')
        .doc(task.userId)
        .collection('tasks')
        .doc(task.id.isNotEmpty ? task.id : null);

    final finalTask = task.copyWith(id: docRef.id);
    await docRef.set(finalTask.toJson());

    // Save initial subtasks if any
    for (int i = 0; i < task.subtasks.length; i++) {
      final sub = task.subtasks[i];
      await addSubtask(task.userId, sub.copyWith(taskId: docRef.id, orderIndex: i));
    }
  }

  Future<void> updateTask(TaskModel task) async {
    // Recalculate priority before saving
    final updatedPriority = PriorityCalculator.calculatePriority(
      deadline: task.deadline,
      weightPercentage: task.weightPercentage,
    );
    final taskWithPriority = task.copyWith(priorityScore: updatedPriority);

    await _firestore
        .collection('users')
        .doc(task.userId)
        .collection('tasks')
        .doc(task.id)
        .update(taskWithPriority.toJson());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    // Delete all subtasks first
    final subtasksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .get();

    for (final doc in subtasksSnapshot.docs) {
      await doc.reference.delete();
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  /// Completes task and updates streak atomically
  Future<Map<String, dynamic>> completeTask(String userId, String taskId) async {
    try {
      // Attempt Cloud Function completeTaskWithStreak
      final callable = _functions.httpsCallable('completeTaskWithStreak');
      final result = await callable.call({'taskId': taskId});
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      // Client-side fallback transaction in case functions are offline/local emulator
      final taskRef = _firestore.collection('users').doc(userId).collection('tasks').doc(taskId);
      final profileRef = _firestore.collection('profiles').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        final taskDoc = await transaction.get(taskRef);
        if (!taskDoc.exists) return {'success': false};

        final profileDoc = await transaction.get(profileRef);
        final profileData = profileDoc.exists ? (profileDoc.data() ?? {}) : <String, dynamic>{};

        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        int currentStreak = (profileData['current_streak'] is num) ? (profileData['current_streak'] as num).toInt() : 0;
        int bestStreak = (profileData['best_streak'] is num) ? (profileData['best_streak'] as num).toInt() : 0;
        final lastCompleted = profileData['last_completed_date']?.toString();

        if (lastCompleted == todayStr) {
          // Already counted today
        } else if (lastCompleted == yesterdayStr) {
          currentStreak += 1;
        } else {
          currentStreak = 1;
        }

        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }

        transaction.update(taskRef, {
          'is_completed': true,
          'completed_at': FieldValue.serverTimestamp(),
        });

        transaction.set(profileRef, {
          'current_streak': currentStreak,
          'best_streak': bestStreak,
          'last_completed_date': todayStr,
        }, SetOptions(merge: true));

        return {
          'success': true,
          'current_streak': currentStreak,
          'best_streak': bestStreak,
          'last_completed_date': todayStr,
        };
      });
    }
  }

  // ----------------------------------------------------
  // SUBTASKS CRUD
  // ----------------------------------------------------
  Stream<List<SubtaskModel>> streamSubtasks(String userId, String taskId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .orderBy('order_index', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SubtaskModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addSubtask(String userId, SubtaskModel subtask) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(subtask.taskId)
        .collection('subtasks')
        .doc(subtask.id.isNotEmpty ? subtask.id : null);

    final finalSubtask = subtask.copyWith(id: docRef.id);
    await docRef.set(finalSubtask.toJson());
  }

  Future<void> updateSubtask(String userId, SubtaskModel subtask) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(subtask.taskId)
        .collection('subtasks')
        .doc(subtask.id)
        .update(subtask.toJson());
  }

  Future<void> deleteSubtask(String userId, String taskId, String subtaskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subtaskId)
        .delete();
  }

  Future<void> toggleSubtaskCompletion(String userId, SubtaskModel subtask) async {
    final newStatus = !subtask.isCompleted;
    final updated = subtask.copyWith(
      isCompleted: newStatus,
      completedAt: newStatus ? DateTime.now() : null,
    );
    await updateSubtask(userId, updated);
  }

  // ----------------------------------------------------
  // CLASS SCHEDULES CRUD
  // ----------------------------------------------------
  Stream<List<ClassScheduleModel>> streamSchedules(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('class_schedules')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ClassScheduleModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.startTotalMinutes.compareTo(b.startTotalMinutes));
      return list;
    });
  }

  Future<void> addSchedule(ClassScheduleModel schedule) async {
    final docRef = _firestore
        .collection('users')
        .doc(schedule.userId)
        .collection('class_schedules')
        .doc(schedule.id.isNotEmpty ? schedule.id : null);

    await docRef.set(schedule.copyWith(id: docRef.id).toJson());
  }

  Future<void> deleteSchedule(String userId, String scheduleId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('class_schedules')
        .doc(scheduleId)
        .delete();
  }

  // ----------------------------------------------------
  // GROUP PROJECTS & MEMBERS
  // ----------------------------------------------------
  Stream<List<GroupProjectModel>> streamGroupProjects(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .snapshots()
        .asyncMap((projectSnap) async {
      final projects = <GroupProjectModel>[];
      for (final doc in projectSnap.docs) {
        final membersSnap = await doc.reference.collection('members').get();
        final members = membersSnap.docs.map((m) => GroupMemberModel.fromFirestore(m)).toList();
        projects.add(GroupProjectModel.fromFirestore(doc, members: members));
      }
      return projects;
    });
  }

  Future<void> createGroupProject({
    required String userId,
    required String title,
    required String courseName,
    required String inviteCode,
    required String leaderName,
    required String leaderPhone,
  }) async {
    final projRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc();

    await projRef.set({
      'id': projRef.id,
      'user_id': userId,
      'title': title,
      'course_name': courseName,
      'invite_code': inviteCode,
      'created_at': FieldValue.serverTimestamp(),
    });

    final memberRef = projRef.collection('members').doc();
    await memberRef.set({
      'id': memberRef.id,
      'project_id': projRef.id,
      'name': leaderName,
      'phone': leaderPhone,
      'role': 'leader',
      'joined_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addGroupMember({
    required String userId,
    required String projectId,
    required String name,
    required String phone,
    String role = 'member',
  }) async {
    final memberRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(projectId)
        .collection('members')
        .doc();

    await memberRef.set({
      'id': memberRef.id,
      'project_id': projectId,
      'name': name,
      'phone': phone,
      'role': role,
      'joined_at': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------
  // CLOUD FUNCTIONS CALLS
  // ----------------------------------------------------
  Future<Map<String, dynamic>> checkAndIncrementAiQuota() async {
    try {
      final callable = _functions.httpsCallable('checkAndIncrementAiQuota');
      final result = await callable.call().timeout(const Duration(seconds: 15));
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      // Local fallback quota enforcement
      final user = currentUser;
      if (user == null) {
        return {'allowed': true, 'message': 'Mode Tamu/Demo', 'remaining': AppConstants.freeAiMonthlyQuota};
      }
      final profile = await getUserProfile(user.uid).timeout(const Duration(seconds: 10));
      if (profile == null) {
        return {'allowed': true, 'message': 'Mode Tamu/Demo', 'remaining': AppConstants.freeAiMonthlyQuota};
      }
      if (profile.isPremium) {
        return {'allowed': true, 'is_premium': true, 'usage_count': profile.aiUsageCount, 'remaining': -1};
      }
      if (profile.aiUsageCount >= AppConstants.freeAiMonthlyQuota) {
        return {
          'allowed': false,
          'is_premium': false,
          'is_quota_exceeded': true,
          'usage_count': profile.aiUsageCount,
          'remaining': 0,
          'message': 'Kuota AI gratis 5x/bulan sudah habis. Upgrade ke Premium!',
        };
      }
      final newCount = profile.aiUsageCount + 1;
      await _firestore.collection('profiles').doc(user.uid).update({
        'ai_usage_count': newCount,
        'ai_usage_reset_date': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      return {
        'allowed': true,
        'is_premium': false,
        'usage_count': newCount,
        'remaining': AppConstants.freeAiMonthlyQuota - newCount,
      };
    }
  }

  Future<Map<String, dynamic>> checkTaskOverload(String userId) async {
    try {
      final callable = _functions.httpsCallable('checkTaskOverload');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      final now = DateTime.now();
      final threshold = now.add(const Duration(days: AppConstants.overloadWindowDays));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('is_completed', isEqualTo: false)
          .get();

      int count = 0;
      double totalWeight = 0;

      for (final doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        if (task.deadline.isBefore(threshold)) {
          count++;
          totalWeight += task.weightPercentage;
        }
      }

      final isOverloaded = count >= AppConstants.overloadTaskCountThreshold ||
          totalWeight >= AppConstants.overloadWeightThreshold;

      return {
        'is_overloaded': isOverloaded,
        'task_count': count,
        'total_weight': totalWeight,
      };
    }
  }

  /// Creates Midtrans Snap transaction for Rp 10.000 TugasKu Premium
  Future<Map<String, dynamic>> createMidtransSnapTransaction() async {
    try {
      final callable = _functions.httpsCallable('createMidtransSnapTransaction');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      final user = currentUser;
      final orderId = 'TUGASKU-PREM-${user?.uid.substring(0, 5) ?? "DEMO"}-${DateTime.now().millisecondsSinceEpoch}';
      return {
        'success': true,
        'order_id': orderId,
        'token': 'demo_snap_$orderId',
        'redirect_url': 'https://app.sandbox.midtrans.com/snap/v2/vtweb/demo_snap_$orderId',
        'amount': 10000,
      };
    }
  }

  /// Verifies Midtrans payment status and activates Premium
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId, {bool simulateSuccess = false}) async {
    try {
      final callable = _functions.httpsCallable('checkPaymentStatus');
      final result = await callable.call({
        'orderId': orderId,
        'simulateSuccess': simulateSuccess,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      if (simulateSuccess && currentUserId != null) {
        final expiry = DateTime.now().add(const Duration(days: 30));
        await _firestore.collection('profiles').doc(currentUserId!).update({
          'is_premium': true,
          'premium_expiry': Timestamp.fromDate(expiry),
        });
        return {
          'status': 'settlement',
          'is_premium': true,
          'message': 'Pembayaran berhasil diverifikasi! Premium telah aktif.',
        };
      }
      return {
        'status': 'pending',
        'is_premium': false,
        'message': 'Menunggu konfirmasi pembayaran via QRIS / Midtrans...',
      };
    }
  }

  Future<bool> subscribePremium(String userId) async {
    try {
      final callable = _functions.httpsCallable('subscribePremium');
      await callable.call();
      return true;
    } catch (_) {
      final expiry = DateTime.now().add(const Duration(days: 30));
      await _firestore.collection('profiles').doc(userId).update({
        'is_premium': true,
        'premium_expiry': Timestamp.fromDate(expiry),
      });
      return true;
    }
  }

  // ----------------------------------------------------
  // AUTH HELPERS: PHONE NORMALIZATION, IDENTIFIER LOGIN, OTP
  // ----------------------------------------------------
  static String normalizePhone(String rawPhone) {
    String value = rawPhone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('0')) {
      value = '62${value.substring(1)}';
    } else if (value.startsWith('8')) {
      value = '62$value';
    } else if (value.startsWith('62')) {
      // keep as is
    } else {
      value = '62$value';
    }
    return '+$value';
  }

  Future<UserCredential> signInWithIdentifierPassword(String identifier, String password) async {
    if (identifier.contains('@')) {
      return await _auth.signInWithEmailAndPassword(email: identifier, password: password);
    }

    final normalized = normalizePhone(identifier);
    final lookupDoc = await _firestore.collection('phone_lookup').doc(normalized).get();
    String? resolvedEmail;
    if (lookupDoc.exists) {
      resolvedEmail = lookupDoc.data()?['email']?.toString();
    } else {
      final profileSnap = await _firestore
          .collection('profiles')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();
      if (profileSnap.docs.isNotEmpty) {
        resolvedEmail = profileSnap.docs.first.data()['email']?.toString();
      }
    }

    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      throw FirebaseAuthException(
        message: 'Nomor telepon belum terdaftar atau belum dihubungkan ke akun.',
        code: 'phone-not-found',
      );
    }

    return await _auth.signInWithEmailAndPassword(email: resolvedEmail, password: password);
  }

  Future<ConfirmationResult> sendPhoneOtpWeb(String phoneNumber) async {
    final normalized = normalizePhone(phoneNumber);
    return await _auth.signInWithPhoneNumber(normalized);
  }

  Future<void> verifyPhoneOtpMobile({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    final normalized = normalizePhone(phoneNumber);
    await _auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: (credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        onAutoVerified(userCredential);
      },
      verificationFailed: (e) {
        onError(e.message ?? 'Verifikasi nomor telepon gagal.');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _ensureProfileExists(user);
      await seedInitialCharterDataIfEmpty(user.uid);
    }
    return userCredential;
  }

  // ----------------------------------------------------
  // PHONE LOOKUP
  // ----------------------------------------------------
  Future<void> upsertPhoneLookup({
    required String phone,
    required String email,
    required String uid,
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return;
    await _firestore.collection('phone_lookup').doc(normalized).set({
      'uid': uid,
      'email': email,
      'phone': normalized,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ----------------------------------------------------
  // PERSONAL AGENDA
  // ----------------------------------------------------
  Stream<List<PersonalAgendaModel>> streamPersonalAgendas(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('personal_agendas')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => PersonalAgendaModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        return a.startTotalMinutes.compareTo(b.startTotalMinutes);
      });
      return list;
    });
  }

  Future<void> addPersonalAgenda(String userId, PersonalAgendaModel agenda) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('personal_agendas')
        .doc(agenda.id.isNotEmpty ? agenda.id : null);
    await docRef.set(agenda.copyWith(id: docRef.id, userId: userId).toJson());
  }

  Future<void> deletePersonalAgenda(String userId, String agendaId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('personal_agendas')
        .doc(agendaId)
        .delete();
  }

  // ----------------------------------------------------
  // GROUP DELIVERABLES & ACTIVITY LOGS
  // ----------------------------------------------------
  Future<void> addGroupDeliverable(String userId, GroupDeliverableModel deliverable) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(deliverable.projectId)
        .collection('deliverables')
        .doc(deliverable.id.isNotEmpty ? deliverable.id : null);

    await docRef.set(deliverable.copyWith(id: docRef.id).toJson());
  }

  Future<void> updateGroupDeliverable(
    String userId,
    GroupDeliverableModel deliverable, {
    required String actorName,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(deliverable.projectId)
        .collection('deliverables')
        .doc(deliverable.id)
        .update(deliverable.copyWith(id: deliverable.id).toJson());

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(deliverable.projectId)
        .collection('activity_logs')
        .add({
      'actor_name': actorName,
      'description': 'memperbarui ${deliverable.title} menjadi ${deliverable.progressPercent}%',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGroupDeliverable(String userId, String projectId, String deliverableId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(projectId)
        .collection('deliverables')
        .doc(deliverableId)
        .delete();
  }

  Stream<List<GroupDeliverableModel>> streamGroupDeliverables(String userId, String projectId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(projectId)
        .collection('deliverables')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupDeliverableModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<GroupActivityModel>> streamGroupActivityLogs(String userId, String projectId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('group_projects')
        .doc(projectId)
        .collection('activity_logs')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupActivityModel.fromFirestore(doc)).toList();
    });
  }

  // ----------------------------------------------------
  // AUTO SEEDER DATA KELOMPOK 6
  // ----------------------------------------------------
  Future<void> seedInitialCharterDataIfEmpty(String userId) async {
    final tasksSnap = await _firestore.collection('users').doc(userId).collection('tasks').limit(1).get();
    final groupsSnap = await _firestore.collection('users').doc(userId).collection('group_projects').limit(1).get();
    if (tasksSnap.docs.isNotEmpty && groupsSnap.docs.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Tasks
    final taskDocs = <Map<String, dynamic>>[
      {
        'user_id': userId,
        'course_name': 'Kewirausahaan',
        'title': 'Finalisasi Project Charter Kelompok 6',
        'description': 'Siapkan bab 1-3 Project Charter untuk presentasi.',
        'deadline': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 8))),
        'weight_percentage': 25,
        'priority_score': 850.0,
        'is_completed': false,
        'completed_at': null,
        'source': 'manual',
        'external_uid': null,
        'is_group_task': true,
      },
      {
        'user_id': userId,
        'course_name': 'Pemrograman Web',
        'title': 'Dashboard Monitoring TugasKu',
        'description': 'Selesaikan halaman monitoring deadline dan prioritas.',
        'deadline': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'weight_percentage': 20,
        'priority_score': 620.0,
        'is_completed': false,
        'completed_at': null,
        'source': 'manual',
        'external_uid': null,
        'is_group_task': false,
      },
      {
        'user_id': userId,
        'course_name': 'Basis Data',
        'title': 'Import Data E-Learning ke Firestore',
        'description': 'Skrip sinkronisasi ICS dan penyusunan struktur koleksi.',
        'deadline': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'weight_percentage': 15,
        'priority_score': 420.0,
        'is_completed': false,
        'completed_at': null,
        'source': 'elearning_ical',
        'external_uid': 'seed-ical-${now.millisecondsSinceEpoch}',
        'is_group_task': false,
      },
    ];

    for (final data in taskDocs) {
      final ref = _firestore.collection('users').doc(userId).collection('tasks').doc();
      batch.set(ref, data);
    }

    // Schedules BM-5A
    final scheduleDocs = <Map<String, dynamic>>[
      {
        'user_id': userId,
        'course_name': 'Kewirausahaan',
        'day_of_week': 5,
        'start_time': '13:00',
        'end_time': '14:40',
        'room': 'Ruang A-105',
      },
      {
        'user_id': userId,
        'course_name': 'Pemrograman Web',
        'day_of_week': 1,
        'start_time': '08:00',
        'end_time': '09:40',
        'room': 'Lab Komputer 302',
      },
      {
        'user_id': userId,
        'course_name': 'Basis Data',
        'day_of_week': 4,
        'start_time': '10:00',
        'end_time': '11:40',
        'room': 'Ruang D-204',
      },
    ];

    for (final data in scheduleDocs) {
      final ref = _firestore.collection('users').doc(userId).collection('class_schedules').doc();
      batch.set(ref, data);
    }

    // Personal agenda
    final agendaRef = _firestore.collection('users').doc(userId).collection('personal_agendas').doc();
    batch.set(agendaRef, {
      'user_id': userId,
      'title': 'Koordinasi Kelompok 6',
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day, 15, 0)),
      'start_time': '15:00',
      'end_time': '16:30',
    });

    // Group project
    final projectRef = _firestore.collection('users').doc(userId).collection('group_projects').doc();
    batch.set(projectRef, {
      'id': projectRef.id,
      'user_id': userId,
      'title': 'TugasKu - Project Charter Kelompok 6',
      'course_name': 'Kewirausahaan (BM - 5A)',
      'invite_code': 'GRP-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'created_at': FieldValue.serverTimestamp(),
    });

    final memberData = [
      {
        'name': 'Mochmad Remano Darusatwiko',
        'phone': '+628123456789',
        'role': 'Project Manager & Front-End Developer (2403421006)',
      },
      {
        'name': 'Muhammad Novansya',
        'phone': '+628123456780',
        'role': 'Back-End Developer & Database Engineer (2403421033)',
      },
      {
        'name': 'Riviera Rafa Andara',
        'phone': '+628123456781',
        'role': 'AI & Integration Specialist (2403421022)',
      },
    ];

    for (final member in memberData) {
      final ref = projectRef.collection('members').doc();
      batch.set(ref, {
        'id': ref.id,
        'project_id': projectRef.id,
        ...member,
        'joined_at': FieldValue.serverTimestamp(),
      });
    }

    // Deliverables
    final deliverables = [
      {
        'title': 'Riset target pasar',
        'type': 'Planning',
        'priority': 1,
        'owner_name': 'Muhammad Novansya',
        'owner_phone': '+628123456780',
        'progress_percent': 100,
        'status': 'completed',
      },
      {
        'title': 'Prototype landing page',
        'type': 'Development',
        'priority': 2,
        'owner_name': 'Riviera Rafa Andara',
        'owner_phone': '+628123456781',
        'progress_percent': 80,
        'status': 'in_progress',
      },
      {
        'title': 'Laporan dan presentasi',
        'type': 'Report',
        'priority': 2,
        'owner_name': 'Mochmad Remano Darusatwiko',
        'owner_phone': '+628123456789',
        'progress_percent': 40,
        'status': 'in_progress',
      },
    ];

    for (final data in deliverables) {
      final ref = projectRef.collection('deliverables').doc();
      batch.set(ref, {
        'project_id': projectRef.id,
        ...data,
      });
    }

    // Activity logs
    final activities = [
      {'actor_name': 'Muhammad Novansya', 'description': 'menyelesaikan riset target pasar'},
      {'actor_name': 'Riviera Rafa Andara', 'description': 'memperbarui prototype menjadi 80%'},
      {'actor_name': 'Mochmad Remano Darusatwiko', 'description': 'membuat draft laporan dan presentasi'},
    ];

    for (final activity in activities) {
      final ref = projectRef.collection('activity_logs').doc();
      batch.set(ref, {
        ...activity,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
