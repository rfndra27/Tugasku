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
  bool didAttemptGoogleSignIn = false;
  bool didAttemptFacebookSignIn = false;
  bool didAttemptPasswordReset = false;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    didAttemptLogin = true;
    throw Exception('Email atau kata sandi salah.');
  }

  @override
  Future<UserCredential> signInWithIdentifierPassword(String identifier, String password) async {
    didAttemptLogin = true;
    throw Exception('Email/Nomor telepon atau kata sandi salah.');
  }

  @override
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String university,
    String nim = '',
    String phone = '',
  }) async {
    didAttemptRegister = true;
    throw Exception('Pendaftaran gagal.');
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    didAttemptGoogleSignIn = true;
    throw Exception('Google login gagal.');
  }

  @override
  Future<UserCredential> signInWithFacebook() async {
    didAttemptFacebookSignIn = true;
    throw Exception('Facebook login gagal.');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    didAttemptPasswordReset = true;
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

    testWidgets('Renders Dark Header, Login tab by default, stacked inputs, remember me, and social login', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Header Elements
      expect(find.text('Go ahead and set up\nyour account'), findsOneWidget);
      expect(find.text('Sign in-up to enjoy the best managing experience'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Pill Switcher Tabs
      expect(find.widgetWithText(Tab, 'Login'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Register'), findsOneWidget);

      // Stacked Input Fields on Login
      expect(find.text('Email atau Nomor Telepon'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Options Row
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Primary Button & Social Login
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('Or login with'), findsOneWidget);
      expect(find.text('Gmail'), findsOneWidget);
      expect(find.text('No. Telp'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('Shows error when clicking login with empty inputs', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Email/Nomor Telepon dan kata sandi wajib diisi.'), findsOneWidget);
    });

    testWidgets('Can switch to Register tab and display registration inputs', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Tap on 'Register' tab
      await tester.tap(find.widgetWithText(Tab, 'Register'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('NIM / NPM'), findsOneWidget);
      expect(find.text('University / Campus'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Nomor Telepon / WhatsApp'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);

      // Tap submit with empty required fields
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      expect(find.text('Mohon lengkapi seluruh field yang wajib diisi.'), findsOneWidget);
    });

    testWidgets('Opens Forgot Password dialog and allows dismissing it', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Kata Sandi'), findsOneWidget);
      expect(find.text('Kirim'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Kata Sandi'), findsNothing);
    });
  });
}
