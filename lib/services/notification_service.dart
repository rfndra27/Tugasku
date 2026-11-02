import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants.dart';
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    // Request permissions for Android 13+
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }
    }

    _isInitialized = true;
  }

  /// Generates a unique notification ID base from taskId hashCode
  int _getBaseId(String taskId) => taskId.hashCode.abs() % 100000;

  /// Schedules 3 tiered notifications for a task:
  /// - H-3 days
  /// - H-1 day (24 hours)
  /// - 3 hours before deadline
  Future<void> scheduleTieredTaskReminders(TaskModel task) async {
    if (kIsWeb) return; // Notifications not scheduled via local plugin on web

    final baseId = _getBaseId(task.id);
    final now = DateTime.now();

    // 1. H-3 Days Notification
    final hMinus3 = task.deadline.subtract(const Duration(days: 3));
    if (hMinus3.isAfter(now)) {
      await _scheduleNotification(
        id: baseId * 10 + 1,
        title: '⏰ H-3 Deadline: ${task.title}',
        body: 'Tugas [${task.courseName}] jatuh tempo 3 hari lagi (${DateFormat('d MMM HH:mm').format(task.deadline)}). Mulai cicil sekarang!',
        scheduledDate: hMinus3,
      );
    }

    // 2. H-1 Day Notification
    final hMinus1 = task.deadline.subtract(const Duration(days: 1));
    if (hMinus1.isAfter(now)) {
      await _scheduleNotification(
        id: baseId * 10 + 2,
        title: '⚠️ H-1 Deadline: ${task.title}',
        body: 'Besok adalah batas akhir pengumpulan [${task.courseName}]! Pastikan tugasmu hampir selesai.',
        scheduledDate: hMinus1,
      );
    }

    // 3. 3 Hours Before Deadline Notification
    final threeHoursBefore = task.deadline.subtract(const Duration(hours: 3));
    if (threeHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId * 10 + 3,
        title: '🚨 3 Jam Terakhir: ${task.title}',
        body: 'Deadline [${task.courseName}] tinggal 3 jam lagi! Cek kelengkapan dan segera kumpulkan ke portal.',
        scheduledDate: threeHoursBefore,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }

  /// Cancels all scheduled reminders for a completed or deleted task
  Future<void> cancelTaskReminders(String taskId) async {
    if (kIsWeb) return;
    final baseId = _getBaseId(taskId);
    await _notificationsPlugin.cancel(id: baseId * 10 + 1);
    await _notificationsPlugin.cancel(id: baseId * 10 + 2);
    await _notificationsPlugin.cancel(id: baseId * 10 + 3);
  }
}
