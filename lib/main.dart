import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/task_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian date formatting for intl
  await initializeDateFormatting('id_ID', null);

  // Initialize Firebase with platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Initialize local notifications service
  await NotificationService().init();

  final firebaseService = FirebaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(firebaseService: firebaseService),
        ),
      ],
      child: const TugasKuApp(),
    ),
  );
}

class TugasKuApp extends StatelessWidget {
  const TugasKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: StreamBuilder<User?>(
        stream: firebaseService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = snapshot.data;
          if (user != null) {
            // Initialize provider with the logged-in user's ID
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<TaskProvider>(context, listen: false).initialize(user.uid);
            });
            return HomeScreen(firebaseService: firebaseService);
          } else {
            return AuthScreen(firebaseService: firebaseService);
          }
        },
      ),
    );
  }
}
