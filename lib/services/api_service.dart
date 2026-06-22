import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final SupabaseClient client = Supabase.instance.client;

  // جلب بيانات من جدول مع فلتر
  Future<List<Map<String, dynamic>>> get(String table, {Map<String, dynamic>? filters}) async {
    var query = client.from(table).select();
    if (filters != null) {
      filters.forEach((key, value) {
        if (key.endsWith('_gte')) {
          query = query.gte(key.replaceAll('_gte', ''), value);
        } else if (key.endsWith('_lte')) {
          query = query.lte(key.replaceAll('_lte', ''), value);
        } else {
          query = query.eq(key, value);
        }
      });
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // تحديث بيانات
  Future<void> update(String table, String id, Map<String, dynamic> data) async {
    await client.from(table).update(data).eq('id', id);
  }
}