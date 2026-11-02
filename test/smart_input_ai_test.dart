import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/ai_service.dart';
import 'package:tugasku/services/firebase_service.dart';

class MockAiFirebaseService extends FirebaseService {
  @override
  Future<Map<String, dynamic>> checkAndIncrementAiQuota() async {
    return {
      'allowed': true,
      'is_premium': false,
      'usage_count': 1,
      'remaining': 4,
    };
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Smart Input AI & Indonesian NLP Parser Tests', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService(firebaseService: MockAiFirebaseService(), apiKey: '');
    });

    test('Extracts task with day, time, and weight percentage', () async {
      const rawText = 'Kumpul laporan praktikum fisika Jumat jam 10 malam ya, bobot nilai 20%';
      final result = await aiService.parseLecturerMessage(rawText);

      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      final task = result.data!;

      expect(task.weightPercentage, equals(20.0));
      expect(task.deadline.hour, equals(22)); // 10 malam = 22:00
      expect(task.deadline.weekday, equals(DateTime.friday));
      expect(task.description, contains(rawText));
    });

    test('Extracts task with relative day "besok" and time "jam 14:30"', () async {
      const rawText = 'Tugas matkul Kecerdasan Buatan dikumpulkan besok jam 14:30, bobot 15%';
      final result = await aiService.parseLecturerMessage(rawText);

      expect(result.success, isTrue);
      final task = result.data!;

      expect(task.courseName.toLowerCase(), contains('kecerdasan buatan'));
      expect(task.weightPercentage, equals(15.0));
      expect(task.deadline.hour, equals(14));
      expect(task.deadline.minute, equals(30));
    });

    test('Pecah Tugas (Task Breakdown) generates 4-5 structured subtasks', () async {
      final result = await aiService.breakdownTask(
        taskId: 'task-123',
        taskTitle: 'Makalah Analisis Algoritma Sorting',
        courseName: 'Desain Analisis Algoritma',
        deadline: DateTime.now().add(const Duration(days: 5)),
      );

      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      final subtasks = result.data!;
      expect(subtasks.length, greaterThanOrEqualTo(4));
      expect(subtasks.first.title, contains('literatur'));
      expect(subtasks.last.title, contains('e-learning'));
    });

    test('AI Assistant provides grounded recommendations based on active tasks', () async {
      final urgentTask = TaskModel(
        id: 't-1',
        userId: 'u-1',
        courseName: 'Basis Data',
        title: 'Laporan Normalisasi Database',
        deadline: DateTime.now().add(const Duration(hours: 6)),
        weightPercentage: 25.0,
      );

      final result = await aiService.askAssistant(
        userQuestion: 'Tugas apa yang harus dicicil duluan?',
        activeTasks: [urgentTask],
      );

      expect(result.success, isTrue);
      expect(result.data, contains('Laporan Normalisasi Database'));
      expect(result.data, contains('Basis Data'));
    });
  });
}
