import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.blue,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.dark,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 26, 30, 158),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: AppRadius.shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: AppRadius.shape),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: AppRadius.shape),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: AppRadius.shape),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey,
      border: OutlineInputBorder(
        borderRadius: AppRadius.border,
        borderSide: BorderSide.none,
      ),
    ),
    chipTheme: ChipThemeData(shape: AppRadius.shape),
    snackBarTheme: SnackBarThemeData(shape: AppRadius.shape),
  );
}
