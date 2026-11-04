import 'package:intl/intl.dart';
import '../models/class_schedule_model.dart';
import '../models/task_model.dart';

enum TimelineItemType {
  classSchedule,
  personalAgenda,
  taskDeadline,
  studyGapRecommendation,
}

class TimelineItem {
  final TimelineItemType type;
  final String title;
  final String subtitle;
  final String timeRange;
  final int startMinutes;
  final int endMinutes;
  final TaskModel? recommendedTask;
  final ClassScheduleModel? classSchedule;
  final TaskModel? deadlineTask;
  final bool hasConflict;

  TimelineItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeRange,
    required this.startMinutes,
    required this.endMinutes,
    this.recommendedTask,
    this.classSchedule,
    this.deadlineTask,
    this.hasConflict = false,
  });
}

class SmartScheduleService {
  /// Generates a sorted daily timeline combining class schedules, deadlines, and auto study-gap blocks
  List<TimelineItem> generateDailyTimeline({
    required DateTime selectedDate,
    required List<ClassScheduleModel> schedules,
    required List<PersonalAgendaModel> personalAgendas,
    required List<TaskModel> activeTasks,
  }) {
    final List<TimelineItem> items = [];
    final dayOfWeek = selectedDate.weekday; // 1 = Monday, 7 = Sunday

    // 1. Filter class schedules for the selected day of week
    final todaySchedules = schedules.where((s) => s.dayOfWeek == dayOfWeek).toList();
    todaySchedules.sort((a, b) => a.startTotalMinutes.compareTo(b.startTotalMinutes));
    final todayAgendas = personalAgendas.where((agenda) {
      return agenda.date.year == selectedDate.year &&
          agenda.date.month == selectedDate.month &&
          agenda.date.day == selectedDate.day;
    }).toList();

    for (final schedule in todaySchedules) {
      final hasConflict = todaySchedules.any((other) =>
          other.id != schedule.id &&
          other.startTotalMinutes < schedule.endTotalMinutes &&
          schedule.startTotalMinutes < other.endTotalMinutes);
      items.add(TimelineItem(
        type: TimelineItemType.classSchedule,
        title: schedule.courseName,
        subtitle: 'Ruang: ${schedule.room.isNotEmpty ? schedule.room : "Online / Belum ditentukan"}',
        timeRange: '${schedule.startTime} - ${schedule.endTime}',
        startMinutes: schedule.startTotalMinutes,
        endMinutes: schedule.endTotalMinutes,
        classSchedule: schedule,
        hasConflict: hasConflict ||
            todayAgendas.any((agenda) =>
                agenda.startTotalMinutes < schedule.endTotalMinutes &&
                schedule.startTotalMinutes < agenda.endTotalMinutes),
      ));
    }

    for (final agenda in todayAgendas) {
      final hasConflict = todaySchedules.any((schedule) =>
          agenda.startTotalMinutes < schedule.endTotalMinutes &&
          schedule.startTotalMinutes < agenda.endTotalMinutes);
      items.add(TimelineItem(
        type: TimelineItemType.personalAgenda,
        title: agenda.title,
        subtitle: 'Agenda pribadi',
        timeRange: '${agenda.startTime} - ${agenda.endTime}',
        startMinutes: agenda.startTotalMinutes,
        endMinutes: agenda.endTotalMinutes,
        hasConflict: hasConflict,
      ));
    }

    // 2. Filter task deadlines on this specific date
    final todayTasks = activeTasks.where((t) {
      return t.deadline.year == selectedDate.year &&
          t.deadline.month == selectedDate.month &&
          t.deadline.day == selectedDate.day;
    }).toList();

    for (final task in todayTasks) {
      final deadlineMinutes = task.deadline.hour * 60 + task.deadline.minute;
      final timeStr = DateFormat('HH:mm').format(task.deadline);
      items.add(TimelineItem(
        type: TimelineItemType.taskDeadline,
        title: 'Deadline: ${task.title}',
        subtitle: '${task.courseName} • Bobot: ${task.weightPercentage.toStringAsFixed(0)}%',
        timeRange: timeStr,
        startMinutes: deadlineMinutes,
        endMinutes: deadlineMinutes,
        deadlineTask: task,
      ));
    }

    // 3. Auto Study-Gap Filler Algorithm:
    // Scans consecutive classes on the selected day.
    // Whenever an empty gap between two classes is >= 60 minutes,
    // automatically inserts a recommended "⚡ Jam Belajar Celah" block
    // (with 15-minute buffer after class and before the next class)
    // assigned to the user's highest-priority active task.
    final TaskModel? highestPriorityTask = activeTasks.isNotEmpty ? activeTasks.first : null;

    for (int i = 0; i < todaySchedules.length - 1; i++) {
      final currentClass = todaySchedules[i];
      final nextClass = todaySchedules[i + 1];

      final gapDuration = nextClass.startTotalMinutes - currentClass.endTotalMinutes;

      // Check if gap is at least 60 minutes
      if (gapDuration >= 60) {
        final gapStart = currentClass.endTotalMinutes + 15; // 15 min buffer after class
        final gapEnd = nextClass.startTotalMinutes - 15; // 15 min buffer before next class

        if (gapEnd > gapStart) {
          final startStr = _formatMinutesToTime(gapStart);
          final endStr = _formatMinutesToTime(gapEnd);
          final durationMins = gapEnd - gapStart;

          final taskTitle = highestPriorityTask != null
              ? 'Cicil: ${highestPriorityTask.title}'
              : 'Belajar Mandiri / Review Materi';
          final taskDesc = highestPriorityTask != null
              ? '${highestPriorityTask.courseName} (Prioritas Tertinggi: ${highestPriorityTask.priorityScore.toStringAsFixed(0)})'
              : 'Waktu santai belajar produktif ($durationMins menit)';

          items.add(TimelineItem(
            type: TimelineItemType.studyGapRecommendation,
            title: '⚡ Jam Belajar Celah ($durationMins Menit)',
            subtitle: '$taskTitle\n$taskDesc',
            timeRange: '$startStr - $endStr',
            startMinutes: gapStart,
            endMinutes: gapEnd,
            recommendedTask: highestPriorityTask,
          ));
        }
      }
    }

    // Sort all timeline items chronologically
    items.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return items;
  }

  String _formatMinutesToTime(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
