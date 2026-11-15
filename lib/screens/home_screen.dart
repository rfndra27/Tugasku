import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/overload_banner_widget.dart';
import '../widgets/streak_counter_widget.dart';
import '../widgets/task_card.dart';
import 'ai_chat_screen.dart';
import 'elearning_sync_dialog.dart';
import 'group_task_screen.dart';
import 'premium_screen.dart';
import 'smart_task_input_dialog.dart';
import 'smart_timeline_screen.dart';
import 'task_detail_screen.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.firebaseService,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  late ConfettiController _confettiController;

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

  void _openSmartInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SmartTaskInputDialog(),
    );
  }

  void _openElearningSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ElearningSyncDialog(),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Keluar dari Akun?', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Text('Anda harus masuk kembali untuk melihat data tugas.', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirm == true) await widget.firebaseService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.check_box_outlined),
        selectedIcon: Icon(Icons.check_box_rounded),
        label: 'Tugas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Jadwal Pintar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome_rounded),
        label: 'Asisten AI',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'Kelompok',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    ];
    final content = IndexedStack(
      index: _currentTabIndex,
      children: [
        _buildTasksTab(),
        const SmartTimelineScreen(),
        const AiChatScreen(),
        const GroupTaskScreen(),
        const EditProfileScreen(isEmbedded: true),
      ],
    );

    return ConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isDesktop
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _currentTabIndex,
                    onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    indicatorColor: AppConstants.primaryColor.withValues(alpha: 0.14),
                    destinations: destinations
                        .map((destination) => NavigationRailDestination(
                              icon: destination.icon,
                              selectedIcon: destination.selectedIcon,
                              label: Text(destination.label),
                            ))
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: _currentTabIndex,
                onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
                destinations: destinations,
              ),
        floatingActionButton: _currentTabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: _openSmartInputDialog,
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Input Pintar AI ✨', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildTasksTab() {
    final provider = context.watch<TaskProvider>();
    final profile = provider.profile;
    final filteredTasks = provider.filteredTasks;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
         title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          borderRadius: BorderRadius.circular(8),
             child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                 Flexible(
                   child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName.isNotEmpty == true ? 'Halo, ${profile!.fullName.split(" ").first} 👋' : 'TugasKu',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                     if (!isCompact)
                       Text(
                         profile?.major.isNotEmpty == true
                          ? '${profile!.major} • ${profile.university.isNotEmpty ? profile.university : "PNJ"}'
                          : (profile?.university.isNotEmpty == true ? profile!.university : AppConstants.appTagline),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                         style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.78)),
                       ),
                  ],
                 ),
                 ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: Color(profile?.avatarColor ?? 0xFF6B8E78),
              child: Text(
                (profile?.fullName.isNotEmpty == true ? profile!.fullName[0] : 'U').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            tooltip: 'Edit profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Aktifkan light mode' : 'Aktifkan dark mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
              size: 19,
            ),
            onPressed: widget.onToggleTheme,
          ),

          // Streak Counter Widget
          StreakCounterWidget(profile: profile),
          const SizedBox(width: 8),

           if (isCompact)
             PopupMenuButton<String>(
               icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
               onSelected: (value) {
                 if (value == 'groups') {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupTaskScreen()));
                 } else if (value == 'premium') {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                 } else if (value == 'logout') {
                   _confirmSignOut();
                 }
               },
               itemBuilder: (_) => const [
                 PopupMenuItem(value: 'groups', child: Text('Tugas Kelompok')),
                 PopupMenuItem(value: 'premium', child: Text('TugasKu Premium')),
                 PopupMenuItem(value: 'logout', child: Text('Keluar')),
               ],
             )
           else ...[
             IconButton(
               icon: const Icon(Icons.groups_rounded, color: Colors.white),
               tooltip: 'Tugas Kelompok',
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupTaskScreen())),
             ),
             IconButton(
               icon: Icon(Icons.workspace_premium_rounded, color: profile?.isPremium == true ? AppConstants.warningColor : Colors.white),
               tooltip: 'TugasKu Premium',
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
             ),
             IconButton(
               icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
               tooltip: 'Keluar',
               onPressed: _confirmSignOut,
             ),
           ],
         ],
       ),
       body: RefreshIndicator(
        color: AppConstants.primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildSummaryCards(provider),
            const SizedBox(height: 12),
            // Overload warning banner
            if (provider.isOverloaded) ...[
              OverloadBannerWidget(
                taskCount: provider.overloadTaskCount,
                totalWeight: provider.overloadTotalWeight,
                onJumpToSchedule: () => setState(() => _currentTabIndex = 1),
              ),
            ],

            // Quick Actions & Sync Bar
            Builder(
              builder: (ctx) {
                final isDark = Theme.of(ctx).brightness == Brightness.dark;
                final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
                final btnBorder = BorderSide(color: isDark ? AppConstants.borderSubtleColor : const Color(0xFFD8E4F2));

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openElearningSyncDialog,
                        icon: Icon(Icons.sync_rounded, size: 16, color: onSurface),
                        label: Text('Sinkron E-Learning (.ics)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).cardColor,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          side: btnBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF6B8E78)),
                        label: Text('Edit Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).cardColor,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          side: btnBorder,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua (${provider.activeTasks.length})', TaskFilter.all, provider),
                  const SizedBox(width: 8),
                  _buildFilterChip('Mendesak (${provider.urgentTasks.length})', TaskFilter.urgent, provider),
                  const SizedBox(width: 8),
                  _buildFilterChip('Kelompok (${provider.groupTasks.length})', TaskFilter.group, provider),
                  const SizedBox(width: 8),
                  _buildFilterChip('Selesai (${provider.completedTasks.length})', TaskFilter.completed, provider),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tasks List
            if (provider.isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppConstants.primaryColor),
                ),
              ),
            ] else if (filteredTasks.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              ...filteredTasks.map((task) {
                return TaskCardWidget(
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                  onComplete: () async {
                    final res = await provider.completeTask(task.id);
                    _confettiController.play();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).cardColor,
                          content: Text(
                            '🎉 Keren! Tugas selesai! Streak bertambah: ${res['current_streak'] ?? 1} hari!',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      );
                    }

                    return true;
                  },
                  onDelete: () async {
                    await provider.deleteTask(task.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).cardColor,
                          content: Text('Tugas berhasil dihapus.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        ),
                      );
                    }
                    return true;
                  },
                );
              }),
            ],
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter, TaskProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = provider.selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
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
        fontSize: 12,
      ),
      onSelected: (_) => provider.setFilter(filter),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_rounded, size: 64, color: AppConstants.borderSubtleColor),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas pada kategori ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol "Input Pintar AI ✨" untuk menambahkan tugas baru dari pesan dosen atau sinkronkan dengan portal e-learning kampusmu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final provider = Provider.of<TaskProvider>(context, listen: false);
              await provider.seedCharterData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data contoh Project Charter Kelompok 6 berhasil dimuat!'),
                    backgroundColor: Color(0xFF6B8E78),
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_stories_rounded, size: 18),
            label: const Text('Muat Data Contoh Kelompok 6'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B8E78),
              side: const BorderSide(color: Color(0xFF6B8E78)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TaskProvider provider) {
    final today = DateTime.now();
    final todayCount = provider.activeTasks.where((task) =>
        task.deadline.year == today.year &&
        task.deadline.month == today.month &&
        task.deadline.day == today.day).length;
    final deliverables = provider.allGroupDeliverables;
    final progress = deliverables.isEmpty
        ? 0
        : (deliverables.map((item) => item.progressPercent).reduce((a, b) => a + b) / deliverables.length).round();

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.timer_outlined,
            label: 'Tugas Hari Ini',
            value: '$todayCount',
            footer: todayCount == 0 ? 'Jadwalmu masih aman' : 'Perlu diselesaikan hari ini',
            color: AppConstants.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.groups_outlined,
            label: 'Proyek Kelompok',
            value: '${provider.groupProjects.length}',
            footer: '$progress% deliverables selesai',
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String footer,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            Text(footer, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
