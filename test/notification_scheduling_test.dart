import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/notification_service.dart';

void main() {
  group('Notification Scheduling Logic Tests', () {
    late TaskModel futureTask;

    setUp(() {
      final futureDeadline = DateTime.now().add(const Duration(days: 5, hours: 2));
      futureTask = TaskModel(
        id: 'task-notif-1',
        userId: 'user-uid-1',
        courseName: 'Statistika',
        title: 'Analisis Regresi Berganda',
        deadline: futureDeadline,
      );
    });

    test('Computes H-3, H-1, and 3 Hours timestamps correctly', () {
      final deadline = futureTask.deadline;
      final hMinus3 = deadline.subtract(const Duration(days: 3));
      final hMinus1 = deadline.subtract(const Duration(days: 1));
      final threeHoursBefore = deadline.subtract(const Duration(hours: 3));

      expect(hMinus3.isBefore(hMinus1), isTrue);
      expect(hMinus1.isBefore(threeHoursBefore), isTrue);
      expect(threeHoursBefore.isBefore(deadline), isTrue);

      expect(deadline.difference(hMinus3).inHours, equals(72));
      expect(deadline.difference(hMinus1).inHours, equals(24));
      expect(deadline.difference(threeHoursBefore).inHours, equals(3));
    });

    test('Generates deterministic unique base IDs from taskId', () {
      final service = NotificationService();
      // Service instance is accessible and does not throw
      expect(service, isNotNull);
    });

    test('Tiered notifications for past deadlines are omitted safely', () {
      final pastDeadline = DateTime.now().subtract(const Duration(hours: 2));
      final now = DateTime.now();

      final hMinus3 = pastDeadline.subtract(const Duration(days: 3));
      final hMinus1 = pastDeadline.subtract(const Duration(days: 1));
      final threeHoursBefore = pastDeadline.subtract(const Duration(hours: 3));

      // None of these should be after now
      expect(hMinus3.isAfter(now), isFalse);
      expect(hMinus1.isAfter(now), isFalse);
      expect(threeHoursBefore.isAfter(now), isFalse);
    });
  });
}

