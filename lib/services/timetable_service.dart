import 'api_service.dart';

class TimetableService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getTimetableForClass(String classId, String section) async {
    return await _api.get('timetable', filters: {
      'class_id': classId,
      'section': section,
    });
  }

  Future<List<Map<String, dynamic>>> getTestsForClass(String classId, String section) async {
    return await _api.get('tests_schedule', filters: {
      'class_id': classId,
      'section': section,
    });
  }

  Future<List<Map<String, dynamic>>> getExamsForClass(String classId, String section) async {
    return await _api.get('exams_schedule', filters: {
      'class_id': classId,
      'section': section,
    });
  }
}