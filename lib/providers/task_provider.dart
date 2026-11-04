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
  List<PersonalAgendaModel> _personalAgendas = [];
  List<GroupProjectModel> _groupProjects = [];
  final Map<String, List<GroupDeliverableModel>> _deliverablesByProject = {};
  final Map<String, List<GroupActivityModel>> _activityByProject = {};
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
  List<PersonalAgendaModel> get personalAgendas => _personalAgendas;
  List<GroupProjectModel> get groupProjects => _groupProjects;
  List<GroupDeliverableModel> deliverablesFor(String projectId) => _deliverablesByProject[projectId] ?? const [];
  List<GroupActivityModel> activityFor(String projectId) => _activityByProject[projectId] ?? const [];
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

    if (AppConstants.useDemoData) {
      _loadDemoData(userId);
      return;
    }

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

  void _loadDemoData(String userId) {
    final now = DateTime.now();
    _profile = UserProfileModel(
      id: userId,
      email: 'mahasiswa@tugasku.app',
      fullName: 'Muhammad Aurakha',
      university: 'Politeknik Negeri Jakarta',
      currentStreak: 4,
      bestStreak: 12,
      aiUsageCount: 1,
    );
    _allTasks = [
      TaskModel(
        id: 'demo-task-1',
        userId: userId,
        courseName: 'Pemrograman Web',
        title: 'Menyelesaikan Dashboard TugasKu',
        description: 'Rapikan tampilan dashboard dan siapkan presentasi singkat.',
        deadline: now.add(const Duration(hours: 8)),
        weightPercentage: 20,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-2',
        userId: userId,
        courseName: 'Basis Data',
        title: 'Laporan Praktikum SQL',
        description: 'Kumpulkan query, hasil pengujian, dan kesimpulan praktikum.',
        deadline: now.add(const Duration(days: 2)),
        weightPercentage: 15,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-3',
        userId: userId,
        courseName: 'Kewirausahaan',
        title: 'Makalah Ide Bisnis Kelompok',
        description: 'Satukan bagian analisis pasar dari seluruh anggota kelompok.',
        deadline: now.add(const Duration(days: 5)),
        weightPercentage: 25,
        isGroupTask: true,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-4',
        userId: userId,
        courseName: 'Pancasila',
        title: 'Membaca Materi Pertemuan 6',
        deadline: now.subtract(const Duration(days: 1)),
        weightPercentage: 10,
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 4)),
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-5',
        userId: userId,
        courseName: 'Matematika Diskrit',
        title: 'Latihan Relasi dan Fungsi',
        description: 'Kerjakan soal nomor 1 sampai 15 di lembar latihan.',
        deadline: now.add(const Duration(days: 1, hours: 5)),
        weightPercentage: 10,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-6',
        userId: userId,
        courseName: 'Sistem Operasi',
        title: 'Rangkuman Proses dan Thread',
        description: 'Buat rangkuman dua halaman untuk diskusi kelas.',
        deadline: now.add(const Duration(days: 3)),
        weightPercentage: 10,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-7',
        userId: userId,
        courseName: 'Pendidikan Agama',
        title: 'Refleksi Materi Etika Profesi',
        deadline: now.add(const Duration(days: 6)),
        weightPercentage: 10,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-8',
        userId: userId,
        courseName: 'Kewirausahaan',
        title: 'Membuat Slide Presentasi',
        description: 'Siapkan slide presentasi dan bagi bagian presentasi dengan anggota.',
        deadline: now.add(const Duration(days: 4)),
        weightPercentage: 15,
        isGroupTask: true,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-9',
        userId: userId,
        courseName: 'Bahasa Inggris',
        title: 'Speaking Practice: Product Pitch',
        deadline: now.add(const Duration(days: 8)),
        weightPercentage: 10,
        source: 'manual',
      ),
      TaskModel(
        id: 'demo-task-10',
        userId: userId,
        courseName: 'Pemrograman Web',
        title: 'Merapikan Dokumentasi API',
        deadline: now.subtract(const Duration(days: 2)),
        weightPercentage: 10,
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 1)),
        source: 'manual',
      ),
    ];
    _allTasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    _schedules = [
      ClassScheduleModel(
        id: 'demo-schedule-1',
        userId: userId,
        courseName: 'Pemrograman Web',
        dayOfWeek: now.weekday,
        startTime: '08:00',
        endTime: '09:40',
        room: 'Lab Komputer 302',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-2',
        userId: userId,
        courseName: 'Basis Data',
        dayOfWeek: 4,
        startTime: '10:00',
        endTime: '11:40',
        room: 'Ruang  D-204',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-3',
        userId: userId,
        courseName: 'Kewirausahaan',
        dayOfWeek: 5,
        startTime: '13:00',
        endTime: '14:40',
        room: 'Ruang A-105',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-4',
        userId: userId,
        courseName: 'Matematika Diskrit',
        dayOfWeek: 1,
        startTime: '10:00',
        endTime: '11:40',
        room: 'Ruang B-201',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-5',
        userId: userId,
        courseName: 'Sistem Operasi',
        dayOfWeek: 2,
        startTime: '08:00',
        endTime: '09:40',
        room: 'Lab Jaringan',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-6',
        userId: userId,
        courseName: 'Bahasa Inggris',
        dayOfWeek: 3,
        startTime: '13:00',
        endTime: '14:40',
        room: 'Ruang C-105',
      ),
      ClassScheduleModel(
        id: 'demo-schedule-7',
        userId: userId,
        courseName: 'Pendidikan Agama',
        dayOfWeek: 5,
        startTime: '08:00',
        endTime: '09:40',
        room: 'Ruang A-202',
      ),
    ];
    _personalAgendas = [
      PersonalAgendaModel(
        id: 'demo-agenda-1',
        userId: userId,
        title: 'Rapat Kelompok 6',
        date: now,
        startTime: '15:00',
        endTime: '16:30',
      ),
      PersonalAgendaModel(
        id: 'demo-agenda-2',
        userId: userId,
        title: 'Review Materi UTS',
        date: now.add(const Duration(days: 1)),
        startTime: '19:00',
        endTime: '20:00',
      ),
    ];
    _groupProjects = [
      GroupProjectModel(
        id: 'demo-group-1',
        userId: userId,
        title: 'Makalah Ide Bisnis Digital',
        courseName: 'Kewirausahaan',
        inviteCode: 'GRP-2407',
        members: [
          GroupMemberModel(
            id: 'demo-member-1',
            projectId: 'demo-group-1',
            name: 'Mochmad Remano Darusatwiko',
            phone: '628123456789',
            role: 'leader',
          ),
          GroupMemberModel(
            id: 'demo-member-2',
            projectId: 'demo-group-1',
            name: 'Muhammad Novansya',
            phone: '628123456780',
          ),
          GroupMemberModel(
            id: 'demo-member-3',
            projectId: 'demo-group-1',
            name: 'Riviera Rafa Andara',
            phone: '628123456781',
          ),
        ],
      ),
    ];
    _deliverablesByProject['demo-group-1'] = [
      GroupDeliverableModel(
        id: 'demo-deliverable-1',
        projectId: 'demo-group-1',
        title: 'Riset target pasar',
        type: 'Planning',
        priority: 1,
        ownerName: 'Muhammad Novansya',
        ownerPhone: '628123456780',
        progressPercent: 100,
        status: DeliverableStatus.completed,
      ),
      GroupDeliverableModel(
        id: 'demo-deliverable-2',
        projectId: 'demo-group-1',
        title: 'Prototype landing page',
        type: 'Development',
        priority: 2,
        ownerName: 'Riviera Rafa Andara',
        ownerPhone: '628123456781',
        progressPercent: 72,
        status: DeliverableStatus.inProgress,
      ),
      GroupDeliverableModel(
        id: 'demo-deliverable-3',
        projectId: 'demo-group-1',
        title: 'Laporan dan presentasi',
        type: 'Report',
        priority: 2,
        ownerName: 'Mochmad Remano Darusatwiko',
        ownerPhone: '628123456789',
        progressPercent: 35,
        status: DeliverableStatus.inProgress,
      ),
    ];
    _activityByProject['demo-group-1'] = [
      GroupActivityModel(actorName: 'Muhammad Novansya', description: 'menyelesaikan riset target pasar'),
      GroupActivityModel(actorName: 'Riviera Rafa Andara', description: 'memperbarui prototype menjadi 72%'),
      GroupActivityModel(actorName: 'Mochmad Remano Darusatwiko', description: 'membuat draft laporan'),
    ];
    _checkOverloadLocally();
    _isLoading = false;
    notifyListeners();
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
    if (AppConstants.useDemoData) {
      _allTasks = [..._allTasks, taskToSave]
        ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      _checkOverloadLocally();
      notifyListeners();
      return;
    }
    await _firebaseService.createTask(taskToSave);
    await _notificationService.scheduleTieredTaskReminders(taskToSave);
  }

  Future<void> updateTask(TaskModel task) async {
    if (_userId == null) return;
    if (AppConstants.useDemoData) {
      final index = _allTasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        _allTasks[index] = task;
        _checkOverloadLocally();
        notifyListeners();
      }
      return;
    }
    await _firebaseService.updateTask(task);
    await _notificationService.cancelTaskReminders(task.id);
    if (!task.isCompleted) {
      await _notificationService.scheduleTieredTaskReminders(task);
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    if (AppConstants.useDemoData) {
      _allTasks.removeWhere((task) => task.id == taskId);
      _checkOverloadLocally();
      notifyListeners();
      return;
    }
    await _firebaseService.deleteTask(_userId!, taskId);
    await _notificationService.cancelTaskReminders(taskId);
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    if (_userId == null) return {'success': false};
    if (AppConstants.useDemoData) {
      final index = _allTasks.indexWhere((task) => task.id == taskId);
      if (index < 0) return {'success': false};
      _allTasks[index] = _allTasks[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      _checkOverloadLocally();
      notifyListeners();
      return {'success': true, 'current_streak': _profile?.currentStreak ?? 1};
    }
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
    if (AppConstants.useDemoData) {
      _schedules = [..._schedules, schedule.copyWith(userId: _userId)];
      notifyListeners();
      return;
    }
    await _firebaseService.addSchedule(schedule.copyWith(userId: _userId));
  }

  Future<void> deleteClassSchedule(String scheduleId) async {
    if (_userId == null) return;
    if (AppConstants.useDemoData) {
      _schedules.removeWhere((schedule) => schedule.id == scheduleId);
      notifyListeners();
      return;
    }
    await _firebaseService.deleteSchedule(_userId!, scheduleId);
  }

  List<TimelineItem> getDailyTimeline(DateTime date) {
    return _smartScheduleService.generateDailyTimeline(
      selectedDate: date,
      schedules: _schedules,
      personalAgendas: _personalAgendas,
      activeTasks: activeTasks,
    );
  }

  void updateDeliverable(GroupDeliverableModel deliverable) {
    final list = [...deliverablesFor(deliverable.projectId)];
    final index = list.indexWhere((item) => item.id == deliverable.id);
    if (index >= 0) {
      list[index] = deliverable;
      _deliverablesByProject[deliverable.projectId] = list;
      (_activityByProject[deliverable.projectId] ??= []).insert(
        0,
        GroupActivityModel(
          actorName: _profile?.fullName ?? 'Anggota',
          description: 'memperbarui ${deliverable.title} menjadi ${deliverable.progressPercent}%',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> importIcalContent(String content, {String platform = 'E-Learning'}) async {
    final events = _icalService.parseIcsContent(content);
    if (events.isEmpty) throw Exception('Tidak ada event valid di file .ics.');
    if (AppConstants.useDemoData) {
      final imported = events.asMap().entries.map((entry) {
        final event = entry.value;
        return TaskModel(
          id: 'ical-demo-${DateTime.now().millisecondsSinceEpoch}-$entry',
          userId: _userId ?? 'demo-user',
          courseName: platform,
          title: event.summary,
          description: event.description,
          deadline: event.deadline,
          source: AppConstants.sourceElearningIcal,
          externalUid: event.uid,
        );
      });
      _allTasks = [..._allTasks, ...imported]
        ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      _checkOverloadLocally();
      notifyListeners();
      return;
    }
    await _icalService.syncIcalContent(
      userId: _userId!,
      icsContent: content,
      platformName: platform,
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
    if (AppConstants.useDemoData) {
      final projectId = 'demo-group-${DateTime.now().millisecondsSinceEpoch}';
      _groupProjects = [
        ..._groupProjects,
        GroupProjectModel(
          id: projectId,
          userId: _userId!,
          title: title,
          courseName: courseName,
          inviteCode: inviteCode,
          members: [
            GroupMemberModel(
              id: '$projectId-leader',
              projectId: projectId,
              name: leaderName,
              phone: leaderPhone,
              role: 'leader',
            ),
          ],
        ),
      ];
      _deliverablesByProject[projectId] = [];
      _activityByProject[projectId] = [
        GroupActivityModel(actorName: leaderName, description: 'membuat proyek kelompok'),
      ];
      notifyListeners();
      return;
    }
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

    if (AppConstants.useDemoData) {
      final index = _groupProjects.indexWhere((project) => project.id == projectId);
      if (index >= 0) {
        final project = _groupProjects[index];
        final updated = project.copyWith(
          members: [
            ...project.members,
            GroupMemberModel(
              id: '$projectId-${DateTime.now().millisecondsSinceEpoch}',
              projectId: projectId,
              name: name,
              phone: phone,
              role: role,
            ),
          ],
        );
        _groupProjects[index] = updated;
        (_activityByProject[projectId] ??= []).insert(
          0,
          GroupActivityModel(actorName: name, description: 'bergabung ke proyek'),
        );
        notifyListeners();
      }
      return;
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
