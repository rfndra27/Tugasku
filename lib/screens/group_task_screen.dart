import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/group_task_model.dart';
import '../models/user_profile_model.dart';
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
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(ctx).dividerColor),
        ),
        title: Text('Buat Proyek Kelompok Baru', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
             children: [
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Pesan tugas (opsional)',
                  hintText: 'Contoh: Tugas presentasi untuk matkul Basis Data, ketua Budi, WA 08123456789',
                  prefixIcon: Icon(Icons.auto_awesome_rounded),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Isi otomatis dengan AI'),
                  onPressed: () {
                    final message = messageController.text.trim();
                    if (message.isEmpty) return;
                    final draft = context.read<TaskProvider>().aiService.parseGroupProjectMessage(message);
                    titleController.text = draft.title;
                    courseController.text = draft.courseName;
                    leaderNameController.text = draft.leaderName;
                    leaderPhoneController.text = draft.leaderPhone;
                  },
                ),
              ),
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
                final code = GroupProjectModel.generateInviteCode();
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

  Future<void> _confirmDeleteProject(GroupProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(ctx).dividerColor),
        ),
        title: Text('Hapus Proyek?', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          'Proyek "${project.title}" beserta semua anggota, deliverable, dan riwayat aktivitasnya akan dihapus permanen.',
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteGroupProject(project.id);
    }
  }

  Future<void> _confirmDeleteMember(GroupProjectModel project, GroupMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(ctx).dividerColor),
        ),
        title: Text('Hapus Anggota?', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          '${member.name} akan dihapus dari proyek "${project.title}".',
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<TaskProvider>().deleteGroupMember(
              projectId: project.id,
              memberId: member.id,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _showAddMemberDialog(GroupProjectModel project, bool isPremium) {    if (!isPremium && project.members.length >= AppConstants.freeMaxGroupMembers) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(ctx).dividerColor),
          ),
          title: Text('👑 Batas Anggota Gratis', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: Text(
            'Akun Gratis maksimal memiliki ${AppConstants.freeMaxGroupMembers} anggota per kelompok. Upgrade ke TugasKu Premium untuk anggota tanpa batas!',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
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

    final searchEmailController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    List<UserProfileModel> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false;
    String selectedEmail = '';
    String? selectedUserId;
    String? selectedAccountMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(ctx).dividerColor),
          ),
          title: Text(
            'Tambah Anggota Kelompok',
            style: TextStyle(
              color: Theme.of(ctx).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search registered account by email
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_search_rounded, size: 18, color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Cari Akun Terdaftar (Email)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: searchEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: 'Ketik email (misal: nama@kampus.ac.id)',
                            suffixIcon: isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : (searchEmailController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          searchEmailController.clear();
                                          setDialogState(() {
                                            searchResults = [];
                                            hasSearched = false;
                                          });
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.search, size: 20),
                                        onPressed: () async {
                                          final q = searchEmailController.text.trim();
                                          if (q.isNotEmpty) {
                                            setDialogState(() => isSearching = true);
                                            final results = await context.read<TaskProvider>().searchUsersByEmail(q);
                                            setDialogState(() {
                                              isSearching = false;
                                              hasSearched = true;
                                              searchResults = results;
                                            });
                                          }
                                        },
                                      )),
                          ),
                          onChanged: (val) async {
                            final q = val.trim();
                            if (q.length >= 2) {
                              setDialogState(() => isSearching = true);
                              final results = await context.read<TaskProvider>().searchUsersByEmail(q);
                              setDialogState(() {
                                isSearching = false;
                                hasSearched = true;
                                searchResults = results;
                              });
                            } else {
                              setDialogState(() {
                                searchResults = [];
                                hasSearched = false;
                              });
                            }
                          },
                          onSubmitted: (val) async {
                            final q = val.trim();
                            if (q.isNotEmpty) {
                              setDialogState(() => isSearching = true);
                              final results = await context.read<TaskProvider>().searchUsersByEmail(q);
                              setDialogState(() {
                                isSearching = false;
                                hasSearched = true;
                                searchResults = results;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search Results List
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final u = searchResults[i];
                          final phoneDisplay = u.phone.isNotEmpty ? u.phone : 'Belum ada nomor WA';
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(u.avatarColor),
                              child: Text(
                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                              '${u.email}\n📱 $phoneDisplay',
                              style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  nameController.text = u.fullName;
                                  phoneController.text = u.phone;
                                  selectedEmail = u.email;
                                  selectedUserId = u.id;
                                  selectedAccountMessage = 'Akun "${u.fullName}" dipilih!';
                                  searchResults = [];
                                  hasSearched = false;
                                });
                              },
                              child: const Text('Pilih', style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  if (hasSearched && searchResults.isEmpty && !isSearching) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        'ℹ️ Email akun belum ditemukan. Anda dapat mengisi nama dan nomor WhatsApp rekan tim secara manual di bawah.',
                        style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)),
                      ),
                    ),
                  ],

                  if (selectedAccountMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$selectedAccountMessage Data nama & WA terisi otomatis.',
                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Informasi Rekan Tim:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Nama lengkap rekan tim tidak boleh kosong.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                final provider = context.read<TaskProvider>();
                try {
                  await provider.addGroupMember(
                    projectId: project.id,
                    name: name,
                    phone: phone,
                    email: selectedEmail,
                    memberUserId: selectedUserId,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Anggota "$name" berhasil ditambahkan!'), backgroundColor: AppConstants.successColor),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Tambah Anggota'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeliverableDialog(GroupProjectModel project) {
    final titleController = TextEditingController();
    String selectedType = 'Planning';
    int selectedPriority = 2;
    String selectedOwnerName = project.members.isNotEmpty ? project.members.first.name : '';
    String selectedOwnerPhone = project.members.isNotEmpty ? project.members.first.phone : '';
    final ownerNameController = TextEditingController(text: selectedOwnerName);
    final ownerPhoneController = TextEditingController(text: selectedOwnerPhone);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(ctx).dividerColor),
          ),
          title: Text('Tambah Deliverable / Subtugas', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Judul Deliverable',
                    hintText: 'Contoh: Riset Pasar / UI Mockup',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe Deliverable'),
                  dropdownColor: Theme.of(ctx).cardColor,
                  items: const [
                    DropdownMenuItem(value: 'Planning', child: Text('Planning')),
                    DropdownMenuItem(value: 'Development', child: Text('Development')),
                    DropdownMenuItem(value: 'Report', child: Text('Report')),
                    DropdownMenuItem(value: 'Testing', child: Text('Testing')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Prioritas'),
                  dropdownColor: Theme.of(ctx).cardColor,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Critical')),
                    DropdownMenuItem(value: 2, child: Text('2 - High')),
                    DropdownMenuItem(value: 3, child: Text('3 - Medium')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedPriority = val);
                  },
                ),
                const SizedBox(height: 12),
                if (project.members.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: project.members.any((m) => m.name == selectedOwnerName) ? selectedOwnerName : null,
                    decoration: const InputDecoration(labelText: 'Pilih PIC Anggota'),
                    dropdownColor: Theme.of(ctx).cardColor,
                    items: project.members.map((m) {
                      final label = m.roleLabel.isNotEmpty ? m.roleLabel : (m.isLeader ? 'Ketua' : 'Anggota');
                      return DropdownMenuItem(value: m.name, child: Text('${m.name} ($label)'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final member = project.members.firstWhere((m) => m.name == val);
                        setDialogState(() {
                          selectedOwnerName = member.name;
                          selectedOwnerPhone = member.phone;
                          ownerNameController.text = member.name;
                          ownerPhoneController.text = member.phone;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: ownerNameController,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Nama PIC', hintText: 'Nama Penanggung Jawab'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerPhoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp PIC', hintText: '08123456789'),
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
                final ownerName = ownerNameController.text.trim();
                final ownerPhone = ownerPhoneController.text.trim();
                if (title.isNotEmpty) {
                  final provider = context.read<TaskProvider>();
                  final deliverable = GroupDeliverableModel(
                    id: '',
                    projectId: project.id,
                    title: title,
                    type: selectedType,
                    priority: selectedPriority,
                    ownerName: ownerName.isNotEmpty ? ownerName : 'Rekan Tim',
                    ownerPhone: ownerPhone,
                    progressPercent: 0,
                    status: DeliverableStatus.pending,
                  );
                  await provider.addDeliverable(deliverable);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah Deliverable'),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subContainerColor = isDark ? AppConstants.inputColor : const Color(0xFFF8FAFC);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
    final borderColor = isDark ? AppConstants.borderSubtleColor : const Color(0xFFE2E8F0);

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
          ? Column(
              children: [
                _buildInvitationBanner(provider),
                Expanded(child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_rounded, size: 72, color: borderColor),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Proyek Kelompok',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat kelompok tugas kuliah untuk membagi subtask per anggota dan kirim pengingat WhatsApp secara instan!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurfaceSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Kelompok Baru'),
                    ),
                  ],
                )))),
              ],
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
                    side: BorderSide(color: borderColor),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: subContainerColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    'Kode: ${project.inviteCode}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfaceSecondary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  tooltip: 'Hapus Proyek',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteProject(project),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          project.title,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: onSurface),
                        ),
                        const SizedBox(height: 16),

                        // Members Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Anggota (${project.members.length}${isPremium ? '' : ' / ${AppConstants.freeMaxGroupMembers}'}):',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
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
                              color: subContainerColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: m.isLeader ? AppConstants.primaryColor : (isDark ? AppConstants.elevatedSurfaceColor : const Color(0xFFCBD5E1)),
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
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                                      ),
                                      Text(
                                        '${m.isLeader ? '👑 Ketua' : 'Anggota'} • ${m.phone}',
                                        style: TextStyle(fontSize: 11, color: onSurfaceSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (m.phone.isNotEmpty) ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        // Find deliverables owned by this member to
                                        // craft a relevant reminder instead of a
                                        // hardcoded generic message.
                                        final owned = provider
                                            .deliverablesFor(project.id)
                                            .where((d) => d.ownerName == m.name || d.ownerPhone == m.phone)
                                            .map((d) => d.title)
                                            .toList();
                                        final reminderTitle = owned.isNotEmpty
                                            ? owned.join(', ')
                                            : 'Koordinasi tugas kelompok';
                                        await WhatsAppService.sendSubtaskReminder(
                                          memberName: m.name,
                                          rawPhoneNumber: m.phone,
                                          subtaskTitle: reminderTitle,
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
                                    icon: const Icon(Icons.chat_rounded, size: 14, color: Colors.white),
                                    label: const Text('Remind WA', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.successColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                                if (!m.isLeader) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.redAccent),
                                    tooltip: 'Hapus Anggota',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteMember(project, m),
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

  Widget _buildInvitationBanner(TaskProvider provider) {
    if (provider.groupInvitations.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: provider.groupInvitations.map((invitation) => ListTile(
          leading: const Icon(Icons.mail_outline_rounded),
          title: Text('Undangan: ${invitation.projectTitle}'),
          subtitle: Text('Dari ${invitation.senderName} • ${invitation.courseName}'),
          trailing: ElevatedButton(
            onPressed: () async {
              try {
                await provider.acceptGroupInvitation(invitation);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undangan diterima.')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menerima undangan: $e')));
              }
            },
            child: const Text('Terima'),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDeliverablesSection(GroupProjectModel project, TaskProvider provider) {
    final deliverables = provider.deliverablesFor(project.id);
    final activities = provider.activityFor(project.id);
    final progress = deliverables.isEmpty
        ? 0
        : (deliverables.map((item) => item.progressPercent).reduce((a, b) => a + b) / deliverables.length).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
    final itemBg = isDark ? AppConstants.inputColor : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppConstants.borderSubtleColor : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Deliverables Tim', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
            TextButton.icon(
              onPressed: () => _showAddDeliverableDialog(project),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text('Tambah Deliverable / Subtugas', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${deliverables.length} Subtugas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceSecondary)),
            Text('$progress% selesai', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: isDark ? AppConstants.elevatedSurfaceColor : const Color(0xFFE2E8F0),
          color: AppConstants.primaryColor,
        ),
        const SizedBox(height: 10),
        ...deliverables.map((deliverable) {
          Color statusBg;
          Color statusTextColor;
          String statusLabel;
          switch (deliverable.status) {
            case DeliverableStatus.completed:
              statusLabel = 'Selesai';
              statusBg = isDark ? const Color(0xFF1B2E24) : const Color(0xFFDCFCE7);
              statusTextColor = isDark ? const Color(0xFF8CF4AF) : const Color(0xFF166534);
              break;
            case DeliverableStatus.inProgress:
              statusLabel = 'Berjalan';
              statusBg = isDark ? const Color(0xFF1E2640) : const Color(0xFFDBEAFE);
              statusTextColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
              break;
            case DeliverableStatus.pending:
              statusLabel = 'Menunggu';
              statusBg = isDark ? const Color(0xFF332515) : const Color(0xFFFEF3C7);
              statusTextColor = isDark ? AppConstants.warningColor : const Color(0xFF92400E);
              break;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: itemBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deliverable.title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Deliverable',
                        onPressed: () => provider.deleteDeliverable(project.id, deliverable.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _DeliverableProgressSlider(
                    deliverable: deliverable,
                    project: project,
                    provider: provider,
                  ),
                  Row(
                    children: [
                      Text('${deliverable.type} • Prioritas ${deliverable.priority}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceSecondary)),
                      const Spacer(),
                      Text(deliverable.ownerName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfaceSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (activities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Riwayat Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 4),
          ...activities.take(3).map((activity) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, size: 18, color: AppConstants.primaryColor),
                title: Text('${activity.actorName} ${activity.description}', style: TextStyle(fontSize: 12, color: onSurfaceSecondary)),
              )),
        ],
      ],
    );
  }
}

/// Local-state progress slider that updates the UI live but persists to the
/// provider (and Firestore) only once, when the user releases the thumb.
class _DeliverableProgressSlider extends StatefulWidget {
  final GroupDeliverableModel deliverable;
  final GroupProjectModel project;
  final TaskProvider provider;

  const _DeliverableProgressSlider({
    required this.deliverable,
    required this.project,
    required this.provider,
  });

  @override
  State<_DeliverableProgressSlider> createState() => _DeliverableProgressSliderState();
}

class _DeliverableProgressSliderState extends State<_DeliverableProgressSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.deliverable.progressPercent.toDouble();
  }

  @override
  void didUpdateWidget(covariant _DeliverableProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliverable.progressPercent != widget.deliverable.progressPercent) {
      _currentValue = widget.deliverable.progressPercent.toDouble();
    }
  }

  void _commit(int percent) {
    widget.provider.updateDeliverable(
      widget.deliverable.copyWith(
        progressPercent: percent,
        status: percent == 100
            ? DeliverableStatus.completed
            : percent == 0
                ? DeliverableStatus.pending
                : DeliverableStatus.inProgress,
      ),
      logActivity: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final percent = _currentValue.round();

    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppConstants.primaryColor,
              inactiveTrackColor: isDark ? AppConstants.elevatedSurfaceColor : const Color(0xFFCBD5E1),
              thumbColor: AppConstants.primaryColor,
            ),
            child: Slider(
              value: _currentValue,
              min: 0,
              max: 100,
              divisions: 20,
              label: '$percent%',
              onChanged: (value) {
                setState(() => _currentValue = value);
              },
              onChangeEnd: (value) {
                _commit(value.round());
              },
            ),
          ),
        ),
        Text('$percent%', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
      ],
    );
  }
}
