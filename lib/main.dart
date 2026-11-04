import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Date formatting init notice: $e');
  }

  // Initialize Firebase with platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Initialize local notifications service (non-web only)
  if (!kIsWeb) {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification init notice: $e');
    }
  }

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

class TugasKuApp extends StatefulWidget {
  const TugasKuApp({super.key});

  @override
  State<TugasKuApp> createState() => _TugasKuAppState();
}

class _TugasKuAppState extends State<TugasKuApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AppConstants.useDemoData
          ? Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<TaskProvider>(context, listen: false).initialize('demo-user');
                });
                return HomeScreen(
                  firebaseService: firebaseService,
                  isDarkMode: _themeMode == ThemeMode.dark,
                  onToggleTheme: _toggleTheme,
                );
              },
            )
          : StreamBuilder<User?>(
              stream: firebaseService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return AuthScreen(firebaseService: firebaseService);
                }

                final user = snapshot.data;
                if (user != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<TaskProvider>(context, listen: false).initialize(user.uid);
                  });
                  return HomeScreen(
                    firebaseService: firebaseService,
                    isDarkMode: _themeMode == ThemeMode.dark,
                    onToggleTheme: _toggleTheme,
                  );
                } else {
                  return AuthScreen(firebaseService: firebaseService);
                }
              },
            ),
    );
  }
}
