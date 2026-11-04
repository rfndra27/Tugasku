import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/user_profile_model.dart';

class StreakCounterWidget extends StatelessWidget {
  final UserProfileModel? profile;

  const StreakCounterWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final streak = profile?.currentStreak ?? 0;
    final isStreakActive = streak > 0;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showStreakDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isStreakActive
              ? (theme.brightness == Brightness.dark ? const Color(0xFF382E1E) : const Color(0xFFFFF4D6))
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isStreakActive ? AppConstants.warningColor : AppConstants.borderSubtleColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isStreakActive ? '🔥' : '💤',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak Hari',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isStreakActive ? AppConstants.warningColor : theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDialog(BuildContext context) {
    final streak = profile?.currentStreak ?? 0;
    final bestStreak = profile?.bestStreak ?? 0;
    final lastDate = profile?.lastCompletedDate ?? 'Belum ada';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: Row(
          children: [
            const Text('🔥 ', style: TextStyle(fontSize: 24)),
            Text('Streak Produktif', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF382E1E) : const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.warningColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    '$streak Hari',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.warningColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selesaikan minimal 1 tugas setiap hari untuk menjaga api streak kamu tetap menyala!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFFFFD56B) : const Color(0xFF8A5A00)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rekor Streak Terbaik:', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
                Text(
                  '$bestStreak Hari',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Terakhir Menyelesaikan:', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65))),
                Text(
                  lastDate,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.onSurface),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppConstants.primaryColor)),
          ),
        ],
      ),
    );
  }
}
