import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const _primary = AppColors.primary;
  static const _secondary = AppColors.secondary;
  static const _surfaceLight = Colors.white;
  static const _surfaceDark = Color(0xFF1F1F1F);
  static const _textLight = Color(0xFF1F2937);
  static const _textDark = Color(0xFFF2F2F2);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: _surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _textLight,
        elevation: 0,
      ),
       inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: const Color(0xFFF9FAFB),
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
         ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: _primary, width: 1.6),
         ),
         errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
         ),
         focusedErrorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
         ),
         contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
       ),
        listTileTheme: const ListTileThemeData(
          textColor: _textLight,
          iconColor: _textLight,
          subtitleTextStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
       filledButtonTheme: FilledButtonThemeData(
         style: FilledButton.styleFrom(
           backgroundColor: _primary,
           foregroundColor: Colors.white,
           minimumSize: const Size.fromHeight(56),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(18),
           ),
           textStyle: const TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w700,
           ),
         ),
       ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
     );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: _surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textDark,
    );

     return ThemeData(
       useMaterial3: true,
       colorScheme: scheme,
       scaffoldBackgroundColor: const Color(0xFF0A0A0A),
       appBarTheme: const AppBarTheme(
         centerTitle: true,
         backgroundColor: Color(0xFF0A0A0A),
         foregroundColor: _textDark,
         elevation: 0,
       ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF353535), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF353535), width: 1.0),
          ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: _primary, width: 1.6),
         ),
         errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
         ),
         focusedErrorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(18),
           borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
         ),
         contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
       ),
       listTileTheme: const ListTileThemeData(
         textColor: _textDark,
         iconColor: _textDark,
         subtitleTextStyle: TextStyle(color: Color(0xFFBDBDBD)),
       ),
       filledButtonTheme: FilledButtonThemeData(
         style: FilledButton.styleFrom(
           backgroundColor: _primary,
           foregroundColor: Colors.white,
           minimumSize: const Size.fromHeight(56),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(18),
           ),
           textStyle: const TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w700,
           ),
         ),
       ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _textDark),
          bodyMedium: TextStyle(color: _textDark),
          bodySmall: TextStyle(color: Color(0xFFBDBDBD)),
          headlineLarge: TextStyle(color: _textDark),
          headlineMedium: TextStyle(color: _textDark),
          headlineSmall: TextStyle(color: _textDark),
          titleLarge: TextStyle(color: _textDark),
          titleMedium: TextStyle(color: _textDark),
          titleSmall: TextStyle(color: _textDark),
          labelLarge: TextStyle(color: _textDark),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A1A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1F1F1F),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
     );
   }
 }
