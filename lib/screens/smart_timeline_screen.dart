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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.borderSubtleColor),
          ),
          title: const Text('Tambah Jadwal Kuliah', style: TextStyle(color: AppConstants.textPrimaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: courseController,
                  style: const TextStyle(color: AppConstants.textPrimaryColor),
                  decoration: const InputDecoration(labelText: 'Nama Mata Kuliah', hintText: 'Algoritma & Struktur Data'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  style: const TextStyle(color: AppConstants.textPrimaryColor),
                  decoration: const InputDecoration(labelText: 'Ruangan / Lab', hintText: 'Lab Komputer 302'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedDay,
                  dropdownColor: AppConstants.cardColor,
                  style: const TextStyle(color: AppConstants.textPrimaryColor),
                  decoration: const InputDecoration(labelText: 'Hari Kuliah'),
                  items: List.generate(7, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_dayLabels[index], style: const TextStyle(color: AppConstants.textPrimaryColor)),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-', style: TextStyle(color: AppConstants.textSecondaryColor)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppConstants.textSecondaryColor))),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final timelineItems = provider.getDailyTimeline(_selectedDate);

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Jadwal & Celah Belajar'),
        actions: [
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
            color: AppConstants.scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDate.weekday == dayIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_dayLabels[index]),
                      selected: isSelected,
                      selectedColor: AppConstants.primaryColor,
                      backgroundColor: AppConstants.cardColor,
                      side: BorderSide(
                        color: isSelected ? AppConstants.primaryColor : AppConstants.borderSubtleColor,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppConstants.textSecondaryColor,
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
          const Divider(height: 1, color: AppConstants.borderSubtleColor),

          // Timeline content
          Expanded(
            child: timelineItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_available_rounded, size: 64, color: AppConstants.borderSubtleColor),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada jadwal di hari ${_dayLabels[_selectedDate.weekday - 1]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimaryColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tambahkan jadwal kuliah dengan menekan tombol (+) di atas untuk melihat rekomendasi celah belajar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddScheduleDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Jadwal Kuliah'),
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
    Color cardColor;
    Color accentColor;
    IconData icon;
    String badgeText;

    switch (item.type) {
      case TimelineItemType.classSchedule:
        cardColor = AppConstants.elevatedSurfaceColor;
        accentColor = AppConstants.successColor;
        icon = Icons.school_rounded;
        badgeText = 'Kuliah';
        break;
      case TimelineItemType.personalAgenda:
        cardColor = const Color(0xFF12302E);
        accentColor = const Color(0xFF2DD4BF);
        icon = Icons.person_outline_rounded;
        badgeText = 'Agenda Pribadi';
        break;
      case TimelineItemType.taskDeadline:
        cardColor = const Color(0xFF332515);
        accentColor = AppConstants.warningColor;
        icon = Icons.alarm_rounded;
        badgeText = 'Deadline';
        break;
      case TimelineItemType.studyGapRecommendation:
        cardColor = AppConstants.elevatedSurfaceColor;
        accentColor = AppConstants.primaryColor;
        icon = Icons.bolt_rounded;
        badgeText = 'Rekomendasi Celah Belajar';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.type == TimelineItemType.studyGapRecommendation
              ? AppConstants.primaryColor.withValues(alpha: 0.6)
              : AppConstants.borderSubtleColor,
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
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.textSecondaryColor),
                        onPressed: () => provider.deleteClassSchedule(item.classSchedule!.id),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
