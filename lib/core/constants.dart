import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'TugasKu';
  static const String appTagline = 'Asisten Deadline Mahasiswa';
  // Set to false when the app is ready to use live Firebase data.
  static const bool useDemoData = true;

  // AI Configuration
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String geminiModel = 'gemini-1.5-flash';
  static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Freemium Constraints
  static const int freeAiMonthlyQuota = 5;
  static const int freeMaxGroupMembers = 3;
  static const int premiumMonthlyPriceIdr = 10000;

  // Midtrans Payment Gateway Configuration
  static const String midtransClientKey = 'SB-Mid-client-DemoTugaskuKey123';
  static const bool midtransIsProduction = false;

  // Task Sources
  static const String sourceManual = 'manual';
  static const String sourceAiSmartInput = 'ai_smart_input';
  static const String sourceElearningIcal = 'elearning_ical';

  // Overload Thresholds
  static const int overloadTaskCountThreshold = 3;
  static const double overloadWeightThreshold = 35.0; // percent
  static const int overloadWindowDays = 3;

  // Notification Channels
  static const String notificationChannelId = 'tugasku_deadlines';
  static const String notificationChannelName = 'Pengingat Deadline Tugas';
  static const String notificationChannelDesc = 'Notifikasi bertingkat H-3, H-1, dan 3 jam sebelum deadline';

  // ----------------------------------------------------
  // BLUE ACADEMIC THEME PALETTE
  // ----------------------------------------------------
  static const Color primaryColor = Color(0xFF8B5CF6);
  static const Color secondaryColor = Color(0xFF2563EB);
  static const Color accentColor = Color(0xFFF59E0B);

  static const Color scaffoldBackgroundColor = Color(0xFF0F0F12);
  static const Color surfaceColor = Color(0xFF18181F);
  static const Color cardColor = Color(0xFF1C1C22);
  static const Color inputColor = Color(0xFF121216);
  static const Color borderSubtleColor = Color(0xFF2A2A35);
  static const Color elevatedSurfaceColor = Color(0xFF242431);

  static const Color textPrimaryColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFF9CA3AF);
  static const Color textLinkColor = Color(0xFF60A5FA);

  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
}
