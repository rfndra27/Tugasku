import 'package:flutter/material.dart';

enum UrgencyLevel {
  overdue,
  critical,
  high,
  medium,
  low,
}

class PriorityCalculator {
  /// Calculates priority score based on urgency and grade weight:
  /// - Overdue (hours_left <= 0): 9999.0
  /// - Critical (hours_left <= 24): (weight * 10.0) + (1000.0 / (hours_left + 0.5))
  /// - Normal (hours_left > 24): (weight * 2.0) + (500.0 / (hours_left / 24.0))
  static double calculatePriority({
    required DateTime deadline,
    required double weightPercentage,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final difference = deadline.difference(currentTime);
    final hoursLeft = difference.inMinutes / 60.0;
    final weight = weightPercentage <= 0 ? 10.0 : weightPercentage;

    if (hoursLeft <= 0) {
      return 9999.0;
    } else if (hoursLeft <= 24.0) {
      return (weight * 10.0) + (1000.0 / (hoursLeft + 0.5));
    } else {
      final daysLeft = hoursLeft / 24.0;
      return (weight * 2.0) + (500.0 / daysLeft);
    }
  }

  /// Categorizes task urgency based on hours remaining and priority score
  static UrgencyLevel getUrgencyLevel({
    required DateTime deadline,
    required double priorityScore,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final difference = deadline.difference(currentTime);
    final hoursLeft = difference.inMinutes / 60.0;

    if (hoursLeft <= 0) {
      return UrgencyLevel.overdue;
    } else if (hoursLeft <= 24.0) {
      return UrgencyLevel.critical;
    } else if (hoursLeft <= 72.0 || priorityScore >= 200.0) {
      return UrgencyLevel.high;
    } else if (hoursLeft <= 168.0 || priorityScore >= 80.0) {
      return UrgencyLevel.medium;
    } else {
      return UrgencyLevel.low;
    }
  }

  /// Returns appropriate badge color based on urgency
  static Color getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.overdue:
        return const Color(0xFFDC2626); // Red 600
      case UrgencyLevel.critical:
        return const Color(0xFFEA580C); // Orange 600
      case UrgencyLevel.high:
        return const Color(0xFFD97706); // Amber 600
      case UrgencyLevel.medium:
        return const Color(0xFF2563EB); // Blue 600
      case UrgencyLevel.low:
        return const Color(0xFF059669); // Emerald 600
    }
  }

  /// Returns Indonesian label for urgency badge
  static String getUrgencyLabel(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.overdue:
        return 'Terlewat';
      case UrgencyLevel.critical:
        return 'Kritis (<24 Jam)';
      case UrgencyLevel.high:
        return 'Mendesak';
      case UrgencyLevel.medium:
        return 'Sedang';
      case UrgencyLevel.low:
        return 'Santai';
    }
  }

  /// Human-readable Indonesian remaining time
  static String formatTimeRemaining(DateTime deadline, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final difference = deadline.difference(currentTime);

    if (difference.isNegative) {
      final passed = difference.abs();
      if (passed.inDays > 0) {
        return 'Terlewat ${passed.inDays} hari';
      } else if (passed.inHours > 0) {
        return 'Terlewat ${passed.inHours} jam';
      } else {
        return 'Terlewat ${passed.inMinutes} menit';
      }
    } else {
      if (difference.inDays > 0) {
        final remainingHours = difference.inHours % 24;
        if (remainingHours > 0) {
          return '${difference.inDays}h ${remainingHours}j lagi';
        }
        return '${difference.inDays} hari lagi';
      } else if (difference.inHours > 0) {
        final remainingMins = difference.inMinutes % 60;
        return '${difference.inHours} jam ${remainingMins}m lagi';
      } else {
        return '${difference.inMinutes} menit lagi';
      }
    }
  }
}

