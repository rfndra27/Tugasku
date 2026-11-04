import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/group_task_model.dart';
import '../providers/task_provider.dart';
import '../services/whatsapp_service.dart';
import 'premium_screen.dart';

class GroupTaskScreen extends StatefulWidget {
  const GroupTaskScreen({super.key});

  @override
  State<GroupTaskScreen> createState() => _GroupTaskScreenState();
}

class _GroupTaskScreenState extends State<GroupTaskScreen> {
  void _showCreateProjectDialog() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    final leaderNameController = TextEditingController();
    final leaderPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: Text('Buat Proyek Kelompok Baru', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Nama Tugas/Proyek', hintText: 'Makalah Kewirausahaan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Mata Kuliah', hintText: 'Kewirausahaan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: leaderNameController,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Nama Ketua Kelompok', hintText: 'Nama Kamu'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: leaderPhoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp Ketua', hintText: '08123456789'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)))),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final course = courseController.text.trim();
              final leaderName = leaderNameController.text.trim();
              final leaderPhone = leaderPhoneController.text.trim();

              if (title.isNotEmpty && leaderName.isNotEmpty) {
                final provider = context.read<TaskProvider>();
                final code = 'GRP-${DateTime.now().millisecondsSinceEpoch % 10000}';
                await provider.createGroupProject(
                  title: title,
                  courseName: course.isNotEmpty ? course : 'Mata Kuliah',
                  inviteCode: code,
                  leaderName: leaderName,
                  leaderPhone: leaderPhone,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Buat Proyek'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(GroupProjectModel project, bool isPremium) {
    if (!isPremium && project.members.length >= AppConstants.freeMaxGroupMembers) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.borderSubtleColor),
          ),
          title: Text('👑 Batas Anggota Gratis', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: Text(
            'Akun Gratis maksimal memiliki ${AppConstants.freeMaxGroupMembers} anggota per kelompok. Upgrade ke TugasKu Premium untuk anggota tanpa batas!',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Nanti Saja', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
              },
              child: const Text('Upgrade Premium (Rp10.000)'),
            ),
          ],
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: Text('Tambah Anggota Kelompok', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'Nama Lengkap Rekan Tim', hintText: 'Budi Santoso'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp (08xxx)', hintText: '08123456789'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final projects = provider.groupProjects;
    final isPremium = provider.profile?.isPremium ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tugas Kelompok & Kolaborasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Buat Kelompok Baru',
            onPressed: _showCreateProjectDialog,
          ),
        ],
      ),
      body: projects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_rounded, size: 72, color: AppConstants.borderSubtleColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Proyek Kelompok',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buat kelompok tugas kuliah untuk membagi subtask per anggota dan kirim pengingat WhatsApp secara instan!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Kelompok Baru'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppConstants.borderSubtleColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                project.courseName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.inputColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppConstants.borderSubtleColor),
                              ),
                              child: Text(
                                'Kode: ${project.inviteCode}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          project.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppConstants.textPrimaryColor),
                        ),
                        const SizedBox(height: 16),

                        // Members Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Anggota (${project.members.length}${isPremium ? '' : ' / ${AppConstants.freeMaxGroupMembers}'}):',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddMemberDialog(project, isPremium),
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                              label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Member items list
                        ...project.members.map((m) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppConstants.inputColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppConstants.borderSubtleColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: m.isLeader ? AppConstants.primaryColor : AppConstants.elevatedSurfaceColor,
                                  child: Text(
                                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                                      ),
                                      Text(
                                        '${m.role == 'leader' ? '👑 Ketua' : 'Anggota'} • ${m.phone}',
                                        style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                if (m.phone.isNotEmpty) ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await WhatsAppService.sendSubtaskReminder(
                                          memberName: m.name,
                                          rawPhoneNumber: m.phone,
                                          subtaskTitle: 'Koordinasi tugas kelompok',
                                          courseName: project.courseName,
                                        );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Theme.of(context).cardColor,
                                              content: Text(e.toString(), style: const TextStyle(color: AppConstants.errorColor)),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.chat_rounded, size: 14, color: Colors.black87),
                                    label: const Text('Remind WA', style: TextStyle(fontSize: 11, color: Colors.black87)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.successColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        _buildDeliverablesSection(project, provider),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDeliverablesSection(GroupProjectModel project, TaskProvider provider) {
    final deliverables = provider.deliverablesFor(project.id);
    final activities = provider.activityFor(project.id);
    final progress = deliverables.isEmpty
        ? 0
        : (deliverables.map((item) => item.progressPercent).reduce((a, b) => a + b) / deliverables.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Deliverables Tim', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
            Text('$progress% selesai', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: AppConstants.elevatedSurfaceColor,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(height: 10),
        ...deliverables.map((deliverable) {
          final statusLabel = deliverable.status == DeliverableStatus.completed
              ? 'Selesai'
              : deliverable.status == DeliverableStatus.inProgress
                  ? 'Berjalan'
                  : 'Menunggu';
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: AppConstants.inputColor,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deliverable.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.textPrimaryColor),
                        ),
                      ),
                      Text(statusLabel, style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: deliverable.progressPercent.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${deliverable.progressPercent}%',
                          onChanged: (value) {
                            final percent = value.round();
                            provider.updateDeliverable(
                              deliverable.copyWith(
                                progressPercent: percent,
                                status: percent == 100
                                    ? DeliverableStatus.completed
                                    : percent == 0
                                        ? DeliverableStatus.pending
                                        : DeliverableStatus.inProgress,
                              ),
                            );
                          },
                        ),
                      ),
                      Text('${deliverable.progressPercent}%'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${deliverable.type} • Prioritas ${deliverable.priority}', style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                      const Spacer(),
                      Text(deliverable.ownerName, style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (activities.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Riwayat Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
          const SizedBox(height: 4),
          ...activities.take(3).map((activity) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, size: 18, color: AppConstants.primaryColor),
                title: Text('${activity.actorName} ${activity.description}', style: const TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor)),
              )),
        ],
      ],
    );
  }
}
