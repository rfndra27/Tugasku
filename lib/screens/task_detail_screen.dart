import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/priority_calculator.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/whatsapp_service.dart';
import '../widgets/confetti_overlay.dart';
import 'premium_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late ConfettiController _confettiController;
  bool _isBreakingDown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleBreakdownAi() async {
    setState(() => _isBreakingDown = true);

    final provider = context.read<TaskProvider>();
    final result = await provider.aiService.breakdownTask(
      taskId: widget.task.id,
      taskTitle: widget.task.title,
      courseName: widget.task.courseName,
      deadline: widget.task.deadline,
    );

    if (!mounted) return;
    setState(() => _isBreakingDown = false);

    if (result.isQuotaExceeded) {
      _showPaywallPrompt(result.errorMessage ?? 'Kuota AI telah habis.');
      return;
    }

    if (result.success && result.data != null) {
      for (final sub in result.data!) {
        await provider.addSubtask(sub);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.cardColor,
            content: Text('Berhasil memecah tugas menjadi ${result.data!.length} subtask!', style: const TextStyle(color: AppConstants.textPrimaryColor)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.cardColor,
            content: Text(result.errorMessage ?? 'Gagal memecah tugas.', style: const TextStyle(color: AppConstants.errorColor)),
          ),
        );
      }
    }
  }

  void _showPaywallPrompt(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: const Text('👑 Kuota AI Habis', style: TextStyle(color: AppConstants.textPrimaryColor)),
        content: Text('$message\n\nUpgrade ke TugasKu Premium hanya Rp10.000/bulan!', style: const TextStyle(color: AppConstants.textSecondaryColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup', style: TextStyle(color: AppConstants.textSecondaryColor))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
            },
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  void _showAddSubtaskDialog() {
    final titleController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: const Text('Tambah Subtask Baru', style: TextStyle(color: AppConstants.textPrimaryColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppConstants.textPrimaryColor),
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Subtask',
                  hintText: 'Misal: Analisis bab 2',
                ),
              ),
              if (widget.task.isGroupTask) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppConstants.textPrimaryColor),
                  decoration: const InputDecoration(
                    labelText: 'Nama Anggota Penanggung Jawab',
                    hintText: 'Nama rekan tim',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppConstants.textPrimaryColor),
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp (08xxx)',
                    hintText: '08123456789',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppConstants.textSecondaryColor))),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final provider = context.read<TaskProvider>();
                final newSub = SubtaskModel(
                  id: '',
                  taskId: widget.task.id,
                  title: title,
                  assignedToName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                  assignedToPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                );
                await provider.addSubtask(newSub);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgency = PriorityCalculator.getUrgencyLevel(
      deadline: widget.task.deadline,
      priorityScore: widget.task.priorityScore,
    );
    final urgencyColor = PriorityCalculator.getUrgencyColor(urgency);
    final urgencyLabel = PriorityCalculator.getUrgencyLabel(urgency);
    final provider = context.watch<TaskProvider>();

    return ConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        backgroundColor: AppConstants.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Detail Tugas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.errorColor),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppConstants.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppConstants.borderSubtleColor),
                    ),
                    title: const Text('Hapus Tugas?', style: TextStyle(color: AppConstants.textPrimaryColor)),
                    content: const Text('Tugas ini beserta seluruh subtasknya akan dihapus permanen.', style: TextStyle(color: AppConstants.textSecondaryColor)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppConstants.textSecondaryColor))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await provider.deleteTask(widget.task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: StreamBuilder<List<SubtaskModel>>(
          stream: provider.streamSubtasks(widget.task.id),
          builder: (context, snapshot) {
            final subtasks = snapshot.data ?? [];
            final completedCount = subtasks.where((s) => s.isCompleted).length;
            final progress = subtasks.isEmpty ? (widget.task.isCompleted ? 1.0 : 0.0) : completedCount / subtasks.length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Card: Info & Urgency
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.borderSubtleColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: urgencyColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              urgencyLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.inputColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.borderSubtleColor),
                            ),
                            child: Text(
                              'Bobot: ${widget.task.weightPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.task.courseName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textPrimaryColor),
                      ),
                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.task.description,
                          style: const TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.alarm_rounded, size: 18, color: AppConstants.textSecondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(widget.task.deadline),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textPrimaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 18, color: AppConstants.warningColor),
                          const SizedBox(width: 8),
                          Text(
                            'Skor Prioritas: ${widget.task.priorityScore.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textPrimaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Subtask Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress Subtask', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
                    Text(
                      '${(progress * 100).toInt()}% ($completedCount/${subtasks.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppConstants.inputColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppConstants.successColor : AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Pecah Tugas AI + Tambah Subtask
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isBreakingDown ? null : _handleBreakdownAi,
                        icon: _isBreakingDown
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(_isBreakingDown ? 'Memecah...' : 'Pecah Tugas ✨'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _showAddSubtaskDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Manual'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        side: const BorderSide(color: AppConstants.borderSubtleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subtasks Checklist
                if (subtasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderSubtleColor),
                    ),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.checklist_rtl_rounded, size: 40, color: AppConstants.borderSubtleColor),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada subtask',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                          ),
                          Text(
                            'Gunakan tombol "Pecah Tugas ✨" agar AI membagi tugas ini jadi langkah kecil!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...subtasks.map((sub) {
                    return Card(
                      color: AppConstants.cardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppConstants.borderSubtleColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: sub.isCompleted,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: AppConstants.successColor,
                              checkColor: Colors.black87,
                              onChanged: (_) async {
                                await provider.toggleSubtask(sub);
                                if (!sub.isCompleted && completedCount + 1 == subtasks.length) {
                                  _confettiController.play();
                                }
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                      color: sub.isCompleted ? AppConstants.textSecondaryColor : AppConstants.textPrimaryColor,
                                    ),
                                  ),
                                  if (sub.assignedToName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Penanggung Jawab: ${sub.assignedToName}',
                                      style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Remind WA button for assigned member if uncompleted
                            if (widget.task.isGroupTask &&
                                !sub.isCompleted &&
                                sub.assignedToPhone != null &&
                                sub.assignedToPhone!.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppConstants.successColor),
                                tooltip: 'Remind WA',
                                onPressed: () async {
                                  try {
                                    await WhatsAppService.sendSubtaskReminder(
                                      memberName: sub.assignedToName ?? 'Rekan Tim',
                                      rawPhoneNumber: sub.assignedToPhone!,
                                      subtaskTitle: sub.title,
                                      courseName: widget.task.courseName,
                                      deadline: widget.task.deadline,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppConstants.cardColor,
                                          content: Text(e.toString(), style: const TextStyle(color: AppConstants.errorColor)),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppConstants.textSecondaryColor),
                              onPressed: () => provider.deleteSubtask(widget.task.id, sub.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 32),

                // Complete Task Action
                if (!widget.task.isCompleted) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await provider.completeTask(widget.task.id);
                      _confettiController.play();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppConstants.cardColor,
                            content: Text(
                              '🎉 Selamat! Tugas selesai! Streak bertambah menjadi ${result['current_streak'] ?? 1} hari!',
                              style: const TextStyle(color: AppConstants.textPrimaryColor),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.black87),
                    label: const Text('Tandai Seluruh Tugas Selesai 🎉', style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
