import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/class_schedule_model.dart';
import '../providers/task_provider.dart';
import '../services/smart_schedule_service.dart';

class SmartTimelineScreen extends StatefulWidget {
  const SmartTimelineScreen({super.key});

  @override
  State<SmartTimelineScreen> createState() => _SmartTimelineScreenState();
}

class _SmartTimelineScreenState extends State<SmartTimelineScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<String> _dayLabels = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  void _showAddScheduleDialog() {
    final courseController = TextEditingController();
    final roomController = TextEditingController();
    int selectedDay = _selectedDate.weekday;
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 40);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppConstants.borderSubtleColor : const Color(0xFFE2E8F0)),
          ),
          title: Text('Tambah Jadwal Kuliah', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: courseController,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Nama Mata Kuliah', hintText: 'Algoritma & Struktur Data'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Ruangan / Lab', hintText: 'Lab Komputer 302'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedDay,
                  dropdownColor: Theme.of(ctx).cardColor,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Hari Kuliah'),
                  items: List.generate(7, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_dayLabels[index], style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDay = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: startTime);
                          if (picked != null) setDialogState(() => startTime = picked);
                        },
                        child: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: endTime);
                          if (picked != null) setDialogState(() => endTime = picked);
                        },
                        child: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)))),
            ElevatedButton(
              onPressed: () async {
                final course = courseController.text.trim();
                if (course.isNotEmpty) {
                  final provider = context.read<TaskProvider>();
                  final schedule = ClassScheduleModel(
                    id: '',
                    userId: provider.userId ?? '',
                    courseName: course,
                    dayOfWeek: selectedDay,
                    startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                    room: roomController.text.trim(),
                  );
                  await provider.addClassSchedule(schedule);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPersonalAgendaDialog() {
    final titleController = TextEditingController();
    DateTime agendaDate = _selectedDate;
    TimeOfDay startTime = const TimeOfDay(hour: 15, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 30);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppConstants.borderSubtleColor : const Color(0xFFE2E8F0)),
          ),
          title: Text('Tambah Agenda Pribadi', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Nama Acara / Agenda',
                    hintText: 'Rapat BEM / Koordinasi Kelompok',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal Acara', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${agendaDate.day}/${agendaDate.month}/${agendaDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: agendaDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => agendaDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: startTime);
                          if (picked != null) setDialogState(() => startTime = picked);
                        },
                        child: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: endTime);
                          if (picked != null) setDialogState(() => endTime = picked);
                        },
                        child: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final provider = context.read<TaskProvider>();
                  final agenda = PersonalAgendaModel(
                    id: '',
                    userId: provider.userId ?? '',
                    title: title,
                    date: agendaDate,
                    startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  );
                  await provider.addPersonalAgenda(agenda);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final timelineItems = provider.getDailyTimeline(_selectedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Jadwal & Celah Belajar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_rounded),
            tooltip: 'Tambah Agenda Pribadi',
            onPressed: _showAddPersonalAgendaDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Jadwal Kuliah',
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Day selector chips (Senin - Minggu)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDate.weekday == dayIndex;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_dayLabels[index]),
                      selected: isSelected,
                      selectedColor: AppConstants.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark ? AppConstants.cardColor : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : (isDark ? AppConstants.borderSubtleColor : const Color(0xFFD8E4F2)),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          final now = DateTime.now();
                          final diff = dayIndex - now.weekday;
                          setState(() {
                            _selectedDate = now.add(Duration(days: diff));
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          // Timeline content
          Expanded(
            child: timelineItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded, size: 64, color: Theme.of(context).dividerColor),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada jadwal di hari ${_dayLabels[_selectedDate.weekday - 1]}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan jadwal kuliah dengan menekan tombol (+) di atas untuk melihat rekomendasi celah belajar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showAddScheduleDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Jadwal Kuliah'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showAddPersonalAgendaDialog,
                                icon: const Icon(Icons.event_note_rounded),
                                label: const Text('Agenda Pribadi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: timelineItems.length,
                    itemBuilder: (context, index) {
                      final item = timelineItems[index];
                      return _buildTimelineCard(item, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(TimelineItem item, TaskProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
    final borderColor = isDark ? AppConstants.borderSubtleColor : const Color(0xFFE2E8F0);
    Color cardColor;
    Color accentColor;
    IconData icon;
    String badgeText;

    switch (item.type) {
      case TimelineItemType.classSchedule:
        cardColor = isDark ? AppConstants.elevatedSurfaceColor : const Color(0xFFDCFCE7);
        accentColor = isDark ? AppConstants.successColor : const Color(0xFF166534);
        icon = Icons.school_rounded;
        badgeText = 'Kuliah';
        break;
      case TimelineItemType.personalAgenda:
        cardColor = isDark ? const Color(0xFF12302E) : const Color(0xFFCCFBF1);
        accentColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
        icon = Icons.person_outline_rounded;
        badgeText = 'Agenda Pribadi';
        break;
      case TimelineItemType.taskDeadline:
        cardColor = isDark ? const Color(0xFF332515) : const Color(0xFFFEF3C7);
        accentColor = isDark ? AppConstants.warningColor : const Color(0xFF92400E);
        icon = Icons.alarm_rounded;
        badgeText = 'Deadline';
        break;
      case TimelineItemType.studyGapRecommendation:
        cardColor = isDark ? AppConstants.elevatedSurfaceColor : const Color(0xFFEDE9FE);
        accentColor = isDark ? AppConstants.primaryColor : const Color(0xFF6D28D9);
        icon = Icons.bolt_rounded;
        badgeText = 'Rekomendasi Celah Belajar';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.type == TimelineItemType.studyGapRecommendation
              ? AppConstants.primaryColor.withValues(alpha: 0.6)
              : borderColor,
          width: item.type == TimelineItemType.studyGapRecommendation ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: accentColor),
                const SizedBox(height: 4),
                Text(
                  item.timeRange,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ),
                    if (item.classSchedule != null) ...[
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: onSurfaceSecondary),
                        onPressed: () => provider.deleteClassSchedule(item.classSchedule!.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                    if (item.personalAgenda != null) ...[
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: onSurfaceSecondary),
                        onPressed: () => provider.deletePersonalAgenda(item.personalAgenda!.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                if (item.hasConflict) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '⚠ Konflik jadwal terdeteksi',
                    style: TextStyle(color: AppConstants.errorColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
