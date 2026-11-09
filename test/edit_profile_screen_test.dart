import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tugasku/core/theme.dart';
import 'package:tugasku/models/class_schedule_model.dart';
import 'package:tugasku/models/group_task_model.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/user_profile_model.dart';
import 'package:tugasku/providers/task_provider.dart';
import 'package:tugasku/screens/edit_profile_screen.dart';
import 'package:tugasku/services/firebase_service.dart';

class MockProfileFirebaseService extends FirebaseService {
  UserProfileModel? updatedProfile;

  @override
  Stream<UserProfileModel?> streamUserProfile(String userId) {
    return Stream.value(UserProfileModel(
      id: userId,
      email: 'mahasiswa@tugasku.app',
      fullName: 'Muhammad Aurakha',
      university: 'Politeknik Negeri Jakarta',
      nim: '2107411001',
      major: 'Broadband Multimedia (BM - 5A)',
      semester: 'Semester 5',
      phone: '628123456789',
      bio: 'Target IPK 3.8 & lulus tepat waktu!',
      avatarColor: 0xFF6B8E78,
      currentStreak: 4,
      bestStreak: 12,
    ));
  }

  @override
  Stream<List<TaskModel>> streamTasks(String userId) => Stream.value([]);

  @override
  Stream<List<ClassScheduleModel>> streamSchedules(String userId) => Stream.value([]);

  @override
  Stream<List<GroupProjectModel>> streamGroupProjects(String userId) => Stream.value([]);

  @override
  Future<void> updateUserProfile(UserProfileModel profile) async {
    updatedProfile = profile;
  }
}

void main() {
  group('EditProfileScreen Widget Tests', () {
    late MockProfileFirebaseService mockService;
    late TaskProvider taskProvider;

    setUp(() {
      mockService = MockProfileFirebaseService();
      taskProvider = TaskProvider(firebaseService: mockService);
      // Initialize demo data for provider
      taskProvider.initialize('test-user-123');
    });

    Widget createEditProfileScreen({bool isEmbedded = false}) {
      return ChangeNotifierProvider<TaskProvider>.value(
        value: taskProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: EditProfileScreen(isEmbedded: isEmbedded),
        ),
      );
    }

    testWidgets('Renders header card with initial avatar, badges, and color options', (tester) async {
      await tester.pumpWidget(createEditProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil Mahasiswa'), findsOneWidget);
      expect(find.text('Muhammad Aurakha'), findsWidgets);
      expect(find.text('mahasiswa@tugasku.app'), findsWidgets);
      expect(find.text('🔥 Streak 4 Hari'), findsOneWidget);
      expect(find.text('Pilih Warna Avatar'), findsOneWidget);
      expect(find.text('Informasi Akademik & Kontak'), findsOneWidget);
    });

    testWidgets('Allows selecting another avatar color and saving profile changes', (tester) async {
      await tester.pumpWidget(createEditProfileScreen(isEmbedded: true));
      await tester.pumpAndSettle();

      // Find color options (each represented by a GestureDetector with AnimatedContainer)
      final colorPickers = find.byType(GestureDetector);
      expect(colorPickers, findsWidgets);

      // Tap on a color option
      await tester.tap(colorPickers.at(2));
      await tester.pumpAndSettle();

      // Scroll down to save button and tap it
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verify SnackBar shown
      expect(find.text('Profil berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets('Shows validation error when required full name is empty', (tester) async {
      await tester.pumpWidget(createEditProfileScreen());
      await tester.pumpAndSettle();

      // Clear full name
      final nameField = find.widgetWithText(TextFormField, 'Muhammad Aurakha');
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
    });
  });
}
