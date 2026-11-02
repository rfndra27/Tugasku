import 'package:flutter/material.dart';
import '../core/constants.dart';

class OverloadBannerWidget extends StatelessWidget {
  final int taskCount;
  final double totalWeight;
  final VoidCallback onJumpToSchedule;

  const OverloadBannerWidget({
    super.key,
    required this.taskCount,
    required this.totalWeight,
    required this.onJumpToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E191B), // Discord Dark Red Surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppConstants.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peringatan Beban Tugas (Overload)!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8B8D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$taskCount tugas menumpuk dalam 3 hari ke depan dengan akumulasi bobot ${totalWeight.toStringAsFixed(0)}%.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE09D9F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJumpToSchedule,
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: const Text('Atur di Jadwal Pintar & Celah Belajar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
