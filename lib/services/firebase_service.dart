import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(fullName);
      // Initialize profile document in profiles/{userId}
      await _firestore.collection('profiles').doc(user.uid).set({
        'id': user.uid,
        'email': email,
        'full_name': fullName,
        'university': university,
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
    return cred;
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
    await _firestore.collection('profiles').doc(profile.id).set(profile.toJson(), SetOptions(merge: true));
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
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (_) {
      // Local fallback quota enforcement
      final user = currentUser;
      if (user == null) {
        return {'allowed': false, 'message': 'Belum login'};
      }
      final profile = await getUserProfile(user.uid);
      if (profile == null) {
        return {'allowed': false, 'message': 'Profil tidak ditemukan'};
      }
      if (profile.isPremium) {
        return {'allowed': true, 'is_premium': true, 'usage_count': profile.aiUsageCount, 'remaining': -1};
      }
      if (profile.aiUsageCount >= AppConstants.freeAiMonthlyQuota) {
        return {
          'allowed': false,
          'is_premium': false,
          'usage_count': profile.aiUsageCount,
          'remaining': 0,
          'message': 'Kuota AI gratis 5x/bulan sudah habis. Upgrade ke Premium!',
        };
      }
      final newCount = profile.aiUsageCount + 1;
      await _firestore.collection('profiles').doc(user.uid).update({
        'ai_usage_count': newCount,
        'ai_usage_reset_date': FieldValue.serverTimestamp(),
      });
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
}
