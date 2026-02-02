import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personalwallet/constant/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import "package:personalwallet/screens/home_screen.dart";

ThemeData appTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
    ),
  );
}

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Dark',
      theme: appTheme(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
