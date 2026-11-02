import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/core/priority_calculator.dart';

void main() {
  group('PriorityCalculator Tests', () {
    test('Overdue tasks should have priority 9999.0', () {
      final now = DateTime.now();
      final overdue = now.subtract(const Duration(hours: 2));
      final score = PriorityCalculator.calculatePriority(
        deadline: overdue,
        weightPercentage: 20.0,
        now: now,
      );
      expect(score, equals(9999.0));
      expect(
        PriorityCalculator.getUrgencyLevel(deadline: overdue, priorityScore: score, now: now),
        equals(UrgencyLevel.overdue),
      );
    });

    test('Critical tasks within 24 hours should have high priority', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(hours: 10));
      final score = PriorityCalculator.calculatePriority(
        deadline: deadline,
        weightPercentage: 20.0,
        now: now,
      );
      // (20 * 10) + (1000 / 10.5) = 200 + 95.23 = 295.23...
      expect(score, greaterThan(200.0));
      expect(
        PriorityCalculator.getUrgencyLevel(deadline: deadline, priorityScore: score, now: now),
        equals(UrgencyLevel.critical),
      );
    });

    test('Normal tasks with long deadline', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 7));
      final score = PriorityCalculator.calculatePriority(
        deadline: deadline,
        weightPercentage: 10.0,
        now: now,
      );
      // (10 * 2) + (500 / 7) = 20 + 71.4 = ~91.4
      expect(score, lessThan(100.0));
      expect(
        PriorityCalculator.getUrgencyLevel(deadline: deadline, priorityScore: score, now: now),
        equals(UrgencyLevel.medium),
      );
    });
  });
}
