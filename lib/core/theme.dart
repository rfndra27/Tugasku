import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.surfaceColor,
        error: AppConstants.errorColor,
        onPrimary: Colors.white,
        onSurface: AppConstants.textPrimaryColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppConstants.scaffoldBackgroundColor,
    );

    return baseDark.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseDark.textTheme).apply(
        bodyColor: AppConstants.textPrimaryColor,
        displayColor: AppConstants.textPrimaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppConstants.borderSubtleColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.borderSubtleColor, width: 1),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppConstants.textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppConstants.textSecondaryColor,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.cardColor,
        modalBackgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        indicatorColor: AppConstants.primaryColor.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              color: AppConstants.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return GoogleFonts.plusJakartaSans(
            color: AppConstants.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppConstants.primaryColor, size: 22);
          }
          return const IconThemeData(color: AppConstants.textSecondaryColor, size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textPrimaryColor,
          side: const BorderSide(color: AppConstants.borderSubtleColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.inputColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppConstants.textSecondaryColor,
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppConstants.textSecondaryColor.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.cardColor,
        disabledColor: AppConstants.inputColor,
        selectedColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(color: AppConstants.borderSubtleColor),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.borderSubtleColor,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppConstants.secondaryColor,
        secondary: AppConstants.primaryColor,
        surface: Colors.white,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FC),
    );

    return baseLight.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseLight.textTheme).apply(
        bodyColor: const Color(0xFF17324D),
        displayColor: const Color(0xFF17324D),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppConstants.primaryColor.withValues(alpha: 0.18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8E4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8E4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
