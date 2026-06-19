import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';                     // للتعامل مع DateFormat
import 'package:intl/date_symbol_data_local.dart';  // لتهيئة بيانات اللغات
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة Supabase
  await Supabase.initialize(
    url: 'https://nqothizwtmvbvyrxoguz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xb3RoaXp3dG12YnZ5cnhvZ3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMjc2ODEsImV4cCI6MjA4MjYwMzY4MX0.Hah1FyYJT-dQI0byUO7pNKB3NZqzkyICPh_0D_zdzis', // مفتاحك
  );

  // 2. تهيئة بيانات التنسيق للغة العربية
  await initializeDateFormatting('ar', null);
  // يمكنك أيضاً تعيين الإعداد الافتراضي للغة
  Intl.defaultLocale = 'ar';

  runApp(const SchoolApp());
}