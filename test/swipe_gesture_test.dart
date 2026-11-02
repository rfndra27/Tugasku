import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/core/theme.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/widgets/task_card.dart';

void main() {
  group('TaskCardWidget Swipe Gestures Tests', () {
    late TaskModel sampleTask;
    bool completedTriggered = false;
    bool deleteTriggered = false;

    setUp(() {
      completedTriggered = false;
      deleteTriggered = false;
      sampleTask = TaskModel(
        id: 'task-test-1',
        userId: 'user-1',
        courseName: 'Pemrograman Mobile',
        title: 'Project TugasKu Flutter',
        description: 'Selesaikan pengerjaan deadline mahasiswa',
        deadline: DateTime.now().add(const Duration(hours: 12)),
        weightPercentage: 20.0,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TaskCardWidget(
            task: sampleTask,
            onTap: () {},
            onComplete: () async {
              completedTriggered = true;
              return true;
            },
            onDelete: () async {
              deleteTriggered = true;
              return true;
            },
          ),
        ),
      );
    }

    testWidgets('Renders card details with urgency and course name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('PEMROGRAMAN MOBILE'), findsOneWidget);
      expect(find.text('Project TugasKu Flutter'), findsOneWidget);
      expect(find.text('Bobot 20%'), findsOneWidget);
      expect(find.text('Kritis (<24 Jam)'), findsOneWidget);
    });

    testWidgets('Swipe Right triggers onComplete', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Drag right from start to end
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(completedTriggered, isTrue);
    });

    testWidgets('Swipe Left shows confirmation dialog for deletion', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Drag left from end to start
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Tugas?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Hapus'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(deleteTriggered, isTrue);
    });
  });
}

