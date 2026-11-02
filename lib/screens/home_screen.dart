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

  const HomeScreen({super.key, required this.firebaseService});

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
    return ConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        backgroundColor: AppConstants.scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildTasksTab(),
            const SmartTimelineScreen(),
            const AiChatScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_box_outlined),
              selectedIcon: Icon(Icons.check_box_rounded),
              label: 'Tugas',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Jadwal Pintar',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Asisten AI',
            ),
          ],
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
      backgroundColor: AppConstants.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName.isNotEmpty == true ? 'Halo, ${profile!.fullName.split(" ").first} 👋' : 'TugasKu',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            Text(
              profile?.university.isNotEmpty == true ? profile!.university : AppConstants.appTagline,
              style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          // Streak Counter Widget
          StreakCounterWidget(profile: profile),
          const SizedBox(width: 8),

          // Group Projects button
          IconButton(
            icon: const Icon(Icons.groups_rounded, color: AppConstants.textSecondaryColor),
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
              color: profile?.isPremium == true ? AppConstants.warningColor : AppConstants.textSecondaryColor,
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
            icon: const Icon(Icons.logout_rounded, color: AppConstants.textSecondaryColor, size: 20),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppConstants.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppConstants.borderSubtleColor),
                  ),
                  title: const Text('Keluar dari Akun?', style: TextStyle(color: AppConstants.textPrimaryColor)),
                  content: const Text(
                    'Anda harus masuk kembali untuk melihat data tugas.',
                    style: TextStyle(color: AppConstants.textSecondaryColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal', style: TextStyle(color: AppConstants.textSecondaryColor)),
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
        backgroundColor: AppConstants.cardColor,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
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
                    icon: const Icon(Icons.sync_rounded, size: 16, color: AppConstants.textPrimaryColor),
                    label: const Text('Sinkron E-Learning (.ics)', style: TextStyle(fontSize: 12, color: AppConstants.textPrimaryColor)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppConstants.cardColor,
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
                          backgroundColor: AppConstants.cardColor,
                          content: Text(
                            '🎉 Keren! Tugas selesai! Streak bertambah: ${res['current_streak'] ?? 1} hari!',
                            style: const TextStyle(color: AppConstants.textPrimaryColor),
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
                        const SnackBar(
                          backgroundColor: AppConstants.cardColor,
                          content: Text('Tugas berhasil dihapus.', style: TextStyle(color: AppConstants.textPrimaryColor)),
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
      backgroundColor: AppConstants.cardColor,
      side: BorderSide(
        color: isSelected ? AppConstants.primaryColor : AppConstants.borderSubtleColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textSecondaryColor,
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
}
