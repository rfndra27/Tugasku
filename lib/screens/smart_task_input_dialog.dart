import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/group_task_model.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';
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

  // Group members state
  final _emailSearchController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberPhoneController = TextEditingController();
  List<UserProfileModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _selectedUserFeedback;
  final List<GroupMemberModel> _addedMembers = [];

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
    _emailSearchController.dispose();
    _memberNameController.dispose();
    _memberPhoneController.dispose();
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
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(ctx).dividerColor),
        ),
        title: Text('👑 Kuota AI Habis', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          '$message\n\nUpgrade ke TugasKu Premium hanya Rp10.000/bulan untuk menikmati input AI tanpa batas!',
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nanti Saja', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
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

  Future<void> _searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await context.read<TaskProvider>().searchUsersByEmail(q);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  void _selectUser(UserProfileModel u) {
    setState(() {
      _memberNameController.text = u.fullName;
      _memberPhoneController.text = u.phone;
      _selectedUserFeedback = 'Akun "${u.fullName}" dipilih! Data nama & WA terisi otomatis.';
      _searchResults = [];
      _hasSearched = false;
    });
  }

  void _addMemberToList() {
    final name = _memberNameController.text.trim();
    final phone = _memberPhoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama rekan tim tidak boleh kosong.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_addedMembers.any((m) => m.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rekan tim "$name" sudah ada di daftar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _addedMembers.add(GroupMemberModel(
        id: 'member-${DateTime.now().millisecondsSinceEpoch}',
        projectId: '',
        name: name,
        phone: phone,
      ));
      _memberNameController.clear();
      _memberPhoneController.clear();
      _emailSearchController.clear();
      _selectedUserFeedback = null;
    });
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
    final initialSubtasks = <SubtaskModel>[];
    if (_isGroupTask && _addedMembers.isNotEmpty) {
      for (int i = 0; i < _addedMembers.length; i++) {
        final m = _addedMembers[i];
        initialSubtasks.add(
          SubtaskModel(
            id: '',
            taskId: '',
            title: 'Bagian tugas: ${m.name}',
            assignedToName: m.name,
            assignedToPhone: m.phone.isNotEmpty ? m.phone : null,
            orderIndex: i,
          ),
        );
      }
    }

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
      subtasks: initialSubtasks,
      isCompleted: false,
    );

    await taskProvider.addTask(task);

    // If it's a group task and members were added, optionally create a linked Group Project
    if (_isGroupTask && _addedMembers.isNotEmpty) {
      try {
        final leaderName = taskProvider.profile?.fullName ?? 'Ketua';
        final leaderPhone = taskProvider.profile?.phone ?? '';
        final inviteCode = 'GRP-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
        await taskProvider.createGroupProject(
          title: title,
          courseName: course.isNotEmpty ? course : 'Tugas Kelompok',
          inviteCode: inviteCode,
          leaderName: leaderName,
          leaderPhone: leaderPhone,
        );
        final latestProjects = taskProvider.groupProjects;
        if (latestProjects.isNotEmpty) {
          final newProj = latestProjects.last;
          for (final m in _addedMembers) {
            await taskProvider.addGroupMember(
              projectId: newProj.id,
              name: m.name,
              phone: m.phone,
            );
          }
        }
      } catch (e) {
        debugPrint('Note: Optional group project sync: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).cardColor,
          content: Text('Tugas berhasil disimpan & pengingat telah dijadwalkan!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
    final borderColor = isDark ? AppConstants.borderSubtleColor : const Color(0xFFD8E4F2);
    final inputBg = isDark ? AppConstants.inputColor : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Text(
                  '✨ Input Pintar AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
                ),
                const Spacer(),
                CloseButton(color: onSurfaceSecondary),
              ],
            ),
            Text(
              'Tempel pesan dosen atau chat grup WhatsApp, AI akan mengekstrak judul, deadline, dan bobot nilai secara otomatis.',
              style: TextStyle(fontSize: 12, color: onSurfaceSecondary),
            ),
            const SizedBox(height: 16),

            // Raw input box
            TextField(
              controller: _rawTextController,
              maxLines: 3,
              style: TextStyle(color: onSurface),
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
                  : const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              label: Text(
                _isAnalyzing ? 'Menganalisis Pesan...' : 'Analisis dengan AI ✨',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(
              'Detail Tugas:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              style: TextStyle(color: onSurface),
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
                    style: TextStyle(color: onSurface),
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
                    style: TextStyle(color: onSurface),
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
                  color: inputBg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppConstants.primaryColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tenggat Waktu (Deadline):', style: TextStyle(fontSize: 11, color: onSurfaceSecondary)),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(_selectedDeadline),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
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
              title: Text('Ini adalah Tugas Kelompok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
              subtitle: Text('Dapat dibagi menjadi subtask per anggota dengan pengingat WA', style: TextStyle(fontSize: 11, color: onSurfaceSecondary)),
              value: _isGroupTask,
              onChanged: (val) => setState(() => _isGroupTask = val),
            ),

            if (_isGroupTask) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group_add_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah Anggota Kelompok',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cari via email terdaftar agar nama & WA terisi otomatis, atau ketik langsung di bawah.',
                      style: TextStyle(fontSize: 11, color: onSurfaceSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Search Email Field
                    TextField(
                      controller: _emailSearchController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelText: 'Cari Akun Terdaftar (Email)',
                        hintText: 'nama@kampus.ac.id',
                        prefixIcon: const Icon(Icons.person_search_rounded, size: 18),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : (_emailSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _emailSearchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _hasSearched = false;
                                      });
                                    },
                                  )
                                : null),
                      ),
                      onChanged: (val) => _searchUsers(val),
                      onSubmitted: (val) => _searchUsers(val),
                    ),

                    // Search Results List
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final u = _searchResults[i];
                            final phoneDisplay = u.phone.isNotEmpty ? u.phone : 'Belum ada WA';
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(u.avatarColor),
                                child: Text(
                                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(u.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: onSurface)),
                              subtitle: Text(
                                '${u.email} • 📱 $phoneDisplay',
                                style: TextStyle(fontSize: 10, color: onSurfaceSecondary),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _selectUser(u),
                                child: const Text('Pilih', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    if (_hasSearched && _searchResults.isEmpty && !_isSearching) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 2),
                        child: Text(
                          'ℹ️ Email tidak ditemukan. Anda dapat mengisi nama dan nomor WhatsApp rekan secara manual.',
                          style: TextStyle(fontSize: 11, color: onSurfaceSecondary),
                        ),
                      ),
                    ],

                    if (_selectedUserFeedback != null) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedUserFeedback!,
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Manual Inputs Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _memberNameController,
                            style: TextStyle(color: onSurface, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              labelText: 'Nama Rekan Tim',
                              hintText: 'Budi Santoso',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _memberPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: onSurface, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              labelText: 'Nomor WA (08xxx)',
                              hintText: '08123456789',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _addMemberToList,
                        icon: const Icon(Icons.person_add_rounded, size: 14, color: Colors.white),
                        label: const Text('Tambah ke Tim', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),

                    // List of added members
                    if (_addedMembers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Anggota Terdaftar (${_addedMembers.length}):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _addedMembers.map((m) {
                          return Chip(
                            backgroundColor: Theme.of(context).cardColor,
                            avatar: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppConstants.primaryColor,
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(
                              '${m.name}${m.phone.isNotEmpty ? ' (${m.phone})' : ''}',
                              style: TextStyle(fontSize: 11, color: onSurface, fontWeight: FontWeight.w500),
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              setState(() => _addedMembers.removeWhere((item) => item.id == m.id));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Simpan Tugas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
