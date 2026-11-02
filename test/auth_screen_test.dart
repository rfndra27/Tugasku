import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/core/theme.dart';
import 'package:tugasku/screens/auth_screen.dart';
import 'package:tugasku/services/firebase_service.dart';

// Mock FirebaseService for widget testing
class MockTestFirebaseService extends FirebaseService {
  bool didAttemptLogin = false;
  bool didAttemptRegister = false;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    didAttemptLogin = true;
    throw Exception('Email atau kata sandi salah.');
  }

  @override
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String university,
  }) async {
    didAttemptRegister = true;
    throw Exception('Pendaftaran gagal.');
  }
}

void main() {
  group('AuthScreen Widget Tests', () {
    late MockTestFirebaseService mockService;

    setUp(() {
      mockService = MockTestFirebaseService();
    });

    Widget createAuthScreen() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: AuthScreen(firebaseService: mockService),
      );
    }

    testWidgets('Renders Login tab by default with email and password fields', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('TugasKu'), findsOneWidget);
      expect(find.text('Asisten Deadline Mahasiswa'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Akun'), findsOneWidget);
      expect(find.text('Email Mahasiswa'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk ke TugasKu'), findsOneWidget);
    });

    testWidgets('Shows error when clicking login with empty inputs', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk ke TugasKu'));
      await tester.pumpAndSettle();

      expect(find.text('Email dan kata sandi wajib diisi.'), findsOneWidget);
    });

    testWidgets('Can switch to Daftar Akun tab and display registration inputs', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Tap on 'Daftar Akun' tab
      await tester.tap(find.text('Daftar Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Nama Kampus / Universitas'), findsOneWidget);
      expect(find.text('Buat Akun Mahasiswa'), findsOneWidget);

      // Tap submit with empty fields
      await tester.tap(find.text('Buat Akun Mahasiswa'));
      await tester.pumpAndSettle();

      expect(find.text('Mohon lengkapi seluruh field yang wajib diisi.'), findsOneWidget);
    });
  });
}
