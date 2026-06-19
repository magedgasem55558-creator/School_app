import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'screens/curriculum_screen.dart';
import 'screens/all_grades_table_screen.dart'; 
import 'screens/attendance_screen.dart';
import 'screens/statistics_screen.dart';

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المدرسة النموذجية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6A1B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A),
          secondary: const Color(0xFFF3E5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5FC),
        fontFamily: 'Cairo',

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'Cairo',
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: const Color(0xFF6A1B9A).withOpacity(0.4),
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIconColor: const Color(0xFF6A1B9A),
        ),

        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.8),
          shadowColor: const Color(0xFF6A1B9A).withOpacity(0.15),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),

        // 🛠️ تم تنظيف هذا الجزء تماماً وحذف أي const داخلية وخارجية منه
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/about': (context) => const AboutScreen(),
        '/curriculum': (context) => const CurriculumScreen(),
      },
    );
  }
}

