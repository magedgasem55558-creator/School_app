import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. ضمان تهيئة محرك فلاتر قبل استدعاء أي خدمات خارجية
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة خدمة الفايربيس (هذا السطر هو المفتاح لمنع الشاشة البيضاء)
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
