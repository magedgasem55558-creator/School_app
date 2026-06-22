import 'api_service.dart';

class DriverService {
  final ApiService _api = ApiService();

  /// جلب السائق المرتبط بالطالب
  Future<Map<String, dynamic>?> getDriverForStudent(String studentId) async {
    // 1. جلب رابط الطالب من student_driver
    final links = await _api.get('student_driver', filters: {'student_id': studentId});
    if (links.isEmpty) return null;

    final driverId = links.first['driver_id'];
    // 2. جلب بيانات السائق من drivers
    final drivers = await _api.get('drivers', filters: {'id': driverId});
    if (drivers.isEmpty) return null;
    return drivers.first;
  }

  /// جلب مواقع السائق في آخر ساعة من آخر موقع مسجل
  Future<List<Map<String, dynamic>>> getRecentLocations(String driverId) async {
    // جلب المواقع بترتيب تنازلي حسب timestamp
    final all = await _api.get('driver_locations', filters: {'driver_id': driverId});
    if (all.isEmpty) return [];

    // ترتيب تنازلي
    all.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    final lastTime = DateTime.parse(all.first['timestamp']).toUtc();
    final cutoff = lastTime.subtract(const Duration(hours: 1));

    // تصفية المواقع خلال الساعة الأخيرة
    final recent = all.where((e) {
      final t = DateTime.parse(e['timestamp']).toUtc();
      return t.isAfter(cutoff);
    }).toList();

    // ترتيب تصاعدي للرسم
    recent.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
    return recent;
  }
}