import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/class_schedule_model.dart';
import '../models/group_task_model.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import '../services/ical_service.dart';
import '../services/notification_service.dart';
import '../services/smart_schedule_service.dart';

enum TaskFilter { all, urgent, group, completed }

class TaskProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  late final AiService _aiService;
  final ICalService _icalService = ICalService();
  final SmartScheduleService _smartScheduleService = SmartScheduleService();
  final NotificationService _notificationService = NotificationService();

  TaskProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _aiService = AiService(firebaseService: firebaseService);
  }

  // State Variables
  String? _userId;
  UserProfileModel? _profile;
  List<TaskModel> _allTasks = [];
  List<ClassScheduleModel> _schedules = [];
  List<GroupProjectModel> _groupProjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Overload state
  bool _isOverloaded = false;
  int _overloadTaskCount = 0;
  double _overloadTotalWeight = 0.0;

  // Selected filter
  TaskFilter _selectedFilter = TaskFilter.all;

  // Stream Subscriptions
  StreamSubscription? _profileSub;
  StreamSubscription? _tasksSub;
  StreamSubscription? _schedulesSub;
  StreamSubscription? _groupsSub;

  // Getters
  String? get userId => _userId;
  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOverloaded => _isOverloaded;
  int get overloadTaskCount => _overloadTaskCount;
  double get overloadTotalWeight => _overloadTotalWeight;
  TaskFilter get selectedFilter => _selectedFilter;
  List<ClassScheduleModel> get schedules => _schedules;
  List<GroupProjectModel> get groupProjects => _groupProjects;
  AiService get aiService => _aiService;

  List<TaskModel> get allTasks => _allTasks;

  List<TaskModel> get activeTasks =>
      _allTasks.where((t) => !t.isCompleted).toList();

  List<TaskModel> get completedTasks =>
      _allTasks.where((t) => t.isCompleted).toList();

  List<TaskModel> get urgentTasks => _allTasks.where((t) {
        if (t.isCompleted) return false;
        final hoursLeft = t.deadline.difference(DateTime.now()).inHours;
        return hoursLeft <= 24 || t.priorityScore >= 200.0;
      }).toList();

  List<TaskModel> get groupTasks =>
      _allTasks.where((t) => t.isGroupTask).toList();

  List<TaskModel> get filteredTasks {
    switch (_selectedFilter) {
      case TaskFilter.urgent:
        return urgentTasks;
      case TaskFilter.group:
        return groupTasks;
      case TaskFilter.completed:
        return completedTasks;
      case TaskFilter.all:
        return activeTasks;
    }
  }

  void setFilter(TaskFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // ----------------------------------------------------
  // INITIALIZATION & REALTIME STREAMS
  // ----------------------------------------------------
  void initialize(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _cancelSubscriptions();

    _isLoading = true;
    notifyListeners();

    // 1. Profile Stream
    _profileSub = _firebaseService.streamUserProfile(userId).listen((profile) {
      _profile = profile;
      notifyListeners();
    });

    // 2. Tasks Stream
    _tasksSub = _firebaseService.streamTasks(userId).listen((tasks) {
      _allTasks = tasks;
      _checkOverloadLocally();
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _isLoading = false;
      notifyListeners();
    });

    // 3. Class Schedules Stream
    _schedulesSub = _firebaseService.streamSchedules(userId).listen((schedules) {
      _schedules = schedules;
      notifyListeners();
    });

    // 4. Group Projects Stream
    _groupsSub = _firebaseService.streamGroupProjects(userId).listen((groups) {
      _groupProjects = groups;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _profileSub?.cancel();
    _tasksSub?.cancel();
    _schedulesSub?.cancel();
    _groupsSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // ----------------------------------------------------
  // TASK ACTIONS
  // ----------------------------------------------------
  Future<void> addTask(TaskModel task) async {
    if (_userId == null) return;
    final taskToSave = task.copyWith(userId: _userId);
    await _firebaseService.createTask(taskToSave);
    await _notificationService.scheduleTieredTaskReminders(taskToSave);
  }

  Future<void> updateTask(TaskModel task) async {
    if (_userId == null) return;
    await _firebaseService.updateTask(task);
    await _notificationService.cancelTaskReminders(task.id);
    if (!task.isCompleted) {
      await _notificationService.scheduleTieredTaskReminders(task);
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    await _firebaseService.deleteTask(_userId!, taskId);
    await _notificationService.cancelTaskReminders(taskId);
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    if (_userId == null) return {'success': false};
    final result = await _firebaseService.completeTask(_userId!, taskId);
    await _notificationService.cancelTaskReminders(taskId);
    return result;
  }

  // ----------------------------------------------------
  // SUBTASK ACTIONS
  // ----------------------------------------------------
  Stream<List<SubtaskModel>> streamSubtasks(String taskId) {
    if (_userId == null) return Stream.value([]);
    return _firebaseService.streamSubtasks(_userId!, taskId);
  }

  Future<void> addSubtask(SubtaskModel subtask) async {
    if (_userId == null) return;
    await _firebaseService.addSubtask(_userId!, subtask);
  }

  Future<void> toggleSubtask(SubtaskModel subtask) async {
    if (_userId == null) return;
    await _firebaseService.toggleSubtaskCompletion(_userId!, subtask);
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    if (_userId == null) return;
    await _firebaseService.deleteSubtask(_userId!, taskId, subtaskId);
  }

  // ----------------------------------------------------
  // OVERLOAD CALCULATION
  // ----------------------------------------------------
  void _checkOverloadLocally() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: AppConstants.overloadWindowDays));

    int count = 0;
    double weight = 0.0;

    for (final task in activeTasks) {
      if (task.deadline.isBefore(threshold)) {
        count++;
        weight += task.weightPercentage;
      }
    }

    _overloadTaskCount = count;
    _overloadTotalWeight = weight;
    _isOverloaded = count >= AppConstants.overloadTaskCountThreshold ||
        weight >= AppConstants.overloadWeightThreshold;
  }

  // ----------------------------------------------------
  // SCHEDULE ACTIONS & SMART TIMELINE
  // ----------------------------------------------------
  Future<void> addClassSchedule(ClassScheduleModel schedule) async {
    if (_userId == null) return;
    await _firebaseService.addSchedule(schedule.copyWith(userId: _userId));
  }

  Future<void> deleteClassSchedule(String scheduleId) async {
    if (_userId == null) return;
    await _firebaseService.deleteSchedule(_userId!, scheduleId);
  }

  List<TimelineItem> getDailyTimeline(DateTime date) {
    return _smartScheduleService.generateDailyTimeline(
      selectedDate: date,
      schedules: _schedules,
      activeTasks: activeTasks,
    );
  }

  // ----------------------------------------------------
  // GROUP COLLABORATION ACTIONS
  // ----------------------------------------------------
  Future<void> createGroupProject({
    required String title,
    required String courseName,
    required String inviteCode,
    required String leaderName,
    required String leaderPhone,
  }) async {
    if (_userId == null) return;
    await _firebaseService.createGroupProject(
      userId: _userId!,
      title: title,
      courseName: courseName,
      inviteCode: inviteCode,
      leaderName: leaderName,
      leaderPhone: leaderPhone,
    );
  }

  Future<void> addGroupMember({
    required String projectId,
    required String name,
    required String phone,
    String role = 'member',
  }) async {
    if (_userId == null) return;

    // Check member quota for free users
    final currentProject = _groupProjects.firstWhere((p) => p.id == projectId);
    final isPremium = _profile?.isPremium ?? false;

    if (!isPremium && currentProject.members.length >= AppConstants.freeMaxGroupMembers) {
      throw Exception('Batas anggota tugas kelompok akun Gratis adalah ${AppConstants.freeMaxGroupMembers} orang. Upgrade ke Premium untuk anggota tanpa batas!');
    }

    await _firebaseService.addGroupMember(
      userId: _userId!,
      projectId: projectId,
      name: name,
      phone: phone,
      role: role,
    );
  }

  // ----------------------------------------------------
  // E-LEARNING ICAL SYNC
  // ----------------------------------------------------
  Future<ICalSyncResult> syncElearning(String icalUrl, {String platform = 'Moodle'}) async {
    if (_userId == null) {
      throw Exception('User belum login');
    }
    return await _icalService.syncElearningCalendar(
      userId: _userId!,
      icalUrl: icalUrl,
      platformName: platform,
    );
  }

  // ----------------------------------------------------
  // PREMIUM SUBSCRIPTION & MIDTRANS PAYMENT GATEWAY
  // ----------------------------------------------------
  Future<Map<String, dynamic>> createMidtransPayment() async {
    return await _firebaseService.createMidtransSnapTransaction();
  }

  Future<Map<String, dynamic>> verifyPaymentStatus(String orderId, {bool simulateSuccess = false}) async {
    final result = await _firebaseService.checkPaymentStatus(orderId, simulateSuccess: simulateSuccess);
    if (result['is_premium'] == true) {
      _profile = _profile?.copyWith(
        isPremium: true,
        premiumExpiry: DateTime.now().add(const Duration(days: 30)),
      );
      notifyListeners();
    }
    return result;
  }

  Future<bool> subscribePremium() async {
    if (_userId == null) return false;
    final success = await _firebaseService.subscribePremium(_userId!);
    if (success) {
      // Local optimistic update
      _profile = _profile?.copyWith(
        isPremium: true,
        premiumExpiry: DateTime.now().add(const Duration(days: 30)),
      );
      notifyListeners();
    }
    return success;
  }
}

