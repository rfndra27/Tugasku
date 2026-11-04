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
    ];
    final content = IndexedStack(
      index: _currentTabIndex,
      children: [
        _buildTasksTab(),
        const SmartTimelineScreen(),
        const AiChatScreen(),
        const GroupTaskScreen(),
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName.isNotEmpty == true ? 'Halo, ${profile!.fullName.split(" ").first} 👋' : 'TugasKu',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              profile?.university.isNotEmpty == true ? profile!.university : AppConstants.appTagline,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.78)),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: widget.isDarkMode ? 'Aktifkan light mode' : 'Aktifkan dark mode',
            child: TextButton.icon(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                widget.isDarkMode ? 'Light' : 'Dark',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              onPressed: widget.onToggleTheme,
            ),
          ),

          // Streak Counter Widget
          StreakCounterWidget(profile: profile),
          const SizedBox(width: 8),

          // Group Projects button
          IconButton(
            icon: const Icon(Icons.groups_rounded, color: Colors.white),
            tooltip: 'Tugas Kelompok',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupTaskScreen()),
              );
            },
          ),

          // Premium badge
          IconButton(
            icon: Icon(
              Icons.workspace_premium_rounded,
              color: profile?.isPremium == true ? AppConstants.warningColor : Colors.white,
            ),
            tooltip: 'TugasKu Premium',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppConstants.borderSubtleColor),
                  ),
                  title: Text('Keluar dari Akun?', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
                  content: Text(
                    'Anda harus masuk kembali untuk melihat data tugas.',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Batal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await widget.firebaseService.signOut();
              }
            },
          ),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openElearningSyncDialog,
                    icon: Icon(Icons.sync_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
                    label: Text('Sinkron E-Learning (.ics)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      side: const BorderSide(color: AppConstants.borderSubtleColor),
                    ),
                  ),
                ),
              ],
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
    final isSelected = provider.selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: isSelected ? AppConstants.primaryColor : AppConstants.borderSubtleColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
        children: const [
          Icon(Icons.task_alt_rounded, size: 64, color: AppConstants.borderSubtleColor),
          SizedBox(height: 16),
          Text(
            'Tidak ada tugas pada kategori ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimaryColor),
          ),
          SizedBox(height: 6),
          Text(
            'Tekan tombol "Input Pintar AI ✨" untuk menambahkan tugas baru dari pesan dosen atau sinkronkan dengan portal e-learning kampusmu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
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
    final deliverables = provider.deliverablesFor('demo-group-1');
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
