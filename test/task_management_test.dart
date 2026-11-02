import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';

void main() {
  group('Task Management & Priority Sorting Tests', () {
    test('Tasks are correctly auto-sorted by priority score descending', () {
      final now = DateTime.now();

      final normalTask = TaskModel(
        id: 't-normal',
        userId: 'u-1',
        courseName: 'Pancasila',
        title: 'Review Makalah',
        deadline: now.add(const Duration(days: 7)),
        weightPercentage: 10.0,
      );

      final criticalTask = TaskModel(
        id: 't-critical',
        userId: 'u-1',
        courseName: 'Struktur Data',
        title: 'Tugas Pohon Biner',
        deadline: now.add(const Duration(hours: 8)),
        weightPercentage: 25.0,
      );

      final overdueTask = TaskModel(
        id: 't-overdue',
        userId: 'u-1',
        courseName: 'Fisika',
        title: 'Laporan Praktikum',
        deadline: now.subtract(const Duration(hours: 1)),
        weightPercentage: 15.0,
      );

      final tasks = [normalTask, criticalTask, overdueTask];
      tasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

      // Order should be: overdue (9999.0) -> critical (~360+) -> normal (<100)
      expect(tasks[0].id, equals('t-overdue'));
      expect(tasks[1].id, equals('t-critical'));
      expect(tasks[2].id, equals('t-normal'));
    });

    test('Overload is triggered when 3 or more tasks are due within 3 days', () {
      final now = DateTime.now();
      final tasksDueWithin3Days = [
        TaskModel(id: '1', userId: 'u', courseName: 'C1', title: 'T1', deadline: now.add(const Duration(days: 1)), weightPercentage: 10.0),
        TaskModel(id: '2', userId: 'u', courseName: 'C2', title: 'T2', deadline: now.add(const Duration(days: 2)), weightPercentage: 10.0),
        TaskModel(id: '3', userId: 'u', courseName: 'C3', title: 'T3', deadline: now.add(const Duration(hours: 30)), weightPercentage: 10.0),
      ];

      final threshold = now.add(const Duration(days: 3));
      final count = tasksDueWithin3Days.where((t) => t.deadline.isBefore(threshold) && !t.isCompleted).length;
      final totalWeight = tasksDueWithin3Days.fold(0.0, (acc, t) => acc + t.weightPercentage);

      final isOverloaded = count >= 3 || totalWeight >= 35.0;
      expect(isOverloaded, isTrue);
      expect(count, equals(3));
    });

    test('Overload is triggered when cumulative weight is >= 35% within 3 days', () {
      final now = DateTime.now();
      final highWeightTasks = [
        TaskModel(id: '1', userId: 'u', courseName: 'C1', title: 'UTS', deadline: now.add(const Duration(days: 2)), weightPercentage: 40.0),
      ];

      final count = highWeightTasks.length;
      final totalWeight = highWeightTasks.first.weightPercentage;

      final isOverloaded = count >= 3 || totalWeight >= 35.0;
      expect(isOverloaded, isTrue);
      expect(totalWeight, equals(40.0));
    });

    test('Completed tasks calculate progress percentage properly', () {
      final task = TaskModel(
        id: '1',
        userId: 'u',
        courseName: 'Matematika',
        title: 'Kalkulus Latihan',
        deadline: DateTime.now().add(const Duration(days: 2)),
        isCompleted: true,
      );
      expect(task.progressPercentage, equals(1.0));
    });
  });
}
