import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'premium_screen.dart';

class SmartTaskInputDialog extends StatefulWidget {
  const SmartTaskInputDialog({super.key});

  @override
  State<SmartTaskInputDialog> createState() => _SmartTaskInputDialogState();
}

class _SmartTaskInputDialogState extends State<SmartTaskInputDialog> {
  final _rawTextController = TextEditingController();
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  final _weightController = TextEditingController(text: '10');
  final _descController = TextEditingController();

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 3));
  bool _isGroupTask = false;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _rawTextController.dispose();
    _titleController.dispose();
    _courseController.dispose();
    _weightController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAi() async {
    final rawText = _rawTextController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _errorMessage = 'Silakan tempel pesan tugas terlebih dahulu.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    final taskProvider = context.read<TaskProvider>();
    final result = await taskProvider.aiService.parseLecturerMessage(rawText);

    if (!mounted) return;

    if (result.isQuotaExceeded) {
      setState(() => _isAnalyzing = false);
      _showPaywallPrompt(result.errorMessage ?? 'Kuota AI telah habis.');
      return;
    }

    if (result.success && result.data != null) {
      final data = result.data!;
      setState(() {
        _titleController.text = data.title;
        _courseController.text = data.courseName;
        _weightController.text = data.weightPercentage.toStringAsFixed(0);
        _descController.text = data.description;
        _selectedDeadline = data.deadline;
        _hasAnalyzed = true;
        _isAnalyzing = false;
      });
    } else {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = result.errorMessage ?? 'Gagal menganalisis pesan.';
      });
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
        content: Text(
          '$message\n\nUpgrade ke TugasKu Premium hanya Rp10.000/bulan untuk menikmati input AI tanpa batas!',
          style: const TextStyle(color: AppConstants.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti Saja', style: TextStyle(color: AppConstants.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
            child: const Text('Lihat Paket Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    final course = _courseController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 10.0;
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Judul tugas tidak boleh kosong.');
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final task = TaskModel(
      id: '',
      userId: taskProvider.userId ?? '',
      courseName: course.isNotEmpty ? course : 'Mata Kuliah',
      title: title,
      description: desc,
      deadline: _selectedDeadline,
      weightPercentage: weight,
      source: _hasAnalyzed ? AppConstants.sourceAiSmartInput : AppConstants.sourceManual,
      isGroupTask: _isGroupTask,
      isCompleted: false,
    );

    await taskProvider.addTask(task);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppConstants.cardColor,
          content: Text('Tugas berhasil disimpan & pengingat telah dijadwalkan!', style: TextStyle(color: AppConstants.textPrimaryColor)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.borderSubtleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: const [
                Text(
                  '✨ Input Pintar AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppConstants.textPrimaryColor),
                ),
                Spacer(),
                CloseButton(color: AppConstants.textSecondaryColor),
              ],
            ),
            const Text(
              'Tempel pesan dosen atau chat grup WhatsApp, AI akan mengekstrak judul, deadline, dan bobot nilai secara otomatis.',
              style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
            ),
            const SizedBox(height: 16),

            // Raw input box
            TextField(
              controller: _rawTextController,
              maxLines: 3,
              style: const TextStyle(color: AppConstants.textPrimaryColor),
              decoration: const InputDecoration(
                hintText: 'Contoh: "Kumpul laporan praktikum fisika Jumat jam 10 malam ya, bobot nilai 20%"',
                labelText: 'Pesan Dosen / Chat Grup WA',
              ),
            ),
            const SizedBox(height: 12),

            // Analyze button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeWithAi,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_isAnalyzing ? 'Menganalisis Pesan...' : 'Analisis dengan AI ✨'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: AppConstants.errorColor),
              ),
            ],

            const Divider(height: 32),

            // Extracted / Manual Form Fields
            const Text(
              'Detail Tugas:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppConstants.textPrimaryColor),
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                hintText: 'Contoh: Laporan Akhir Praktikum',
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _courseController,
                    style: const TextStyle(color: AppConstants.textPrimaryColor),
                    decoration: const InputDecoration(
                      labelText: 'Mata Kuliah',
                      hintText: 'Fisika Dasar',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppConstants.textPrimaryColor),
                    decoration: const InputDecoration(
                      labelText: 'Bobot (%)',
                      hintText: '10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deadline picker button
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppConstants.inputColor,
                  border: Border.all(color: AppConstants.borderSubtleColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppConstants.primaryColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tenggat Waktu (Deadline):', style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(_selectedDeadline),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text('Ubah', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Group Task Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppConstants.primaryColor,
              title: const Text('Ini adalah Tugas Kelompok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimaryColor)),
              subtitle: const Text('Dapat dibagi menjadi subtask per anggota dengan pengingat WA', style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
              value: _isGroupTask,
              onChanged: (val) => setState(() => _isGroupTask = val),
            ),

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}
