import 'package:intl/intl.dart';
import 'api_service.dart';

class ParentService {
  final ApiService _api = ApiService();


 Future<Map<String, dynamic>?> getClassByLevelNumber(String level) async {
    final data = await _api.get('classes');
    for (var c in data) {
      if (c['name'].toString().contains(level)) {
        return c;
      }
    }
    return null;
  }

  // جلب مواد صف معين
  Future<List<Map<String, dynamic>>> getSubjectsByClass(String classId) async {
    return _api.get('subjects', filters: {'class_id': classId});
  }

  // جلب جميع مواد الصف (بديلة لاستخدامها في الجدول)
  Future<List<Map<String, dynamic>>> getStudentSubjects(String classId) async {
    return _api.get('subjects', filters: {'class_id': classId});
  }

  // جلب درجات الطالب التفصيلية
  Future<List<Map<String, dynamic>>> getDetailedGrades(
      String studentId, int year, String semester) async {
    final grades = await _api.get('grades', filters: {
      'student_id': studentId,
      'academic_year': year,
      'semester': semester,
    });
    return grades;
  }

  // جلب جميع اختبارات/أنشطة مادة دراسية
  Future<List<Map<String, dynamic>>> getExams(String subjectId) async {
    return _api.get('exams', filters: {'subject_id': subjectId});
  }

  // جلب درجات طالب لمادة معينة في سنة وفصل محددين
  Future<List<Map<String, dynamic>>> getStudentGradesForSubject(
      String studentId, String subjectId, int year, String semester) async {
    final grades = await _api.get('grades', filters: {
      'student_id': studentId,
      'subject_id': subjectId,
      'academic_year': year,
      'semester': semester,
    });
    return grades;
  }

  // حساب العلامة الشهرية (من 20) لطالب في شهر معين
  Future<double> getStudentMonthlyMark(
      String studentId, String monthKey, String subjectId, String semester) async {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final allExams = await getExams(subjectId);
    final monthExams = allExams.where((e) {
      final d = DateTime.parse(e['exam_date']);
      return d.year == year &&
          d.month == month &&
          e['name'] != 'امتحان الفصل الأول' &&
          e['name'] != 'امتحان الفصل الثاني';
    }).toList();

    if (monthExams.isEmpty) return 0.0;

    final grades = await getStudentGradesForSubject(studentId, subjectId, year, semester);
    double totalScore = 0, totalMax = 0;
    for (final exam in monthExams) {
      final grade = grades.firstWhere(
        (g) => g['exam_id'] == exam['id'],
        orElse: () => {'score': 0},
      );
      totalScore += (grade['score'] ?? 0).toDouble();
      totalMax += (exam['max_score'] ?? 0).toDouble();
    }
    return totalMax > 0 ? (totalScore / totalMax) * 20 : 0;
  }

  // جلب الحضور
  Future<List<Map<String, dynamic>>> getAttendance(
      String studentId, String start, String end) async {
    return _api.get('attendance', filters: {
      'student_id': studentId,
      'date_gte': start,
      'date_lte': end,
    });
  }


// جلب جميع سجلات الحضور لطالب خلال سنة معينة
Future<List<Map<String, dynamic>>> getYearAttendance(String studentId, int year) async {
  final start = '$year-01-01';
  final end = '$year-12-31';
  return getAttendance(studentId, start, end);
}


  // جلب بيانات الصف (للماليات)
  Future<Map<String, dynamic>?> getClassData(String classId) async {
    final data = await _api.get('classes', filters: {'id': classId});
    return data.isNotEmpty ? data.first : null;
  }

  // جلب اختبارات مادة
  Future<List<Map<String, dynamic>>> getSubjectExams(String subjectId) async {
    return _api.get('exams', filters: {'subject_id': subjectId});
  }

  // جلب اسم الصف من level
  Future<Map<String, dynamic>?> getClassByName(String level) async {
    final data = await _api.get('classes', filters: {'name': level});
    return data.isNotEmpty ? data.first : null;
  }
  // دالة آمنة لإرجاع بيانات الصف - لا تعيد null أبداً
  Future<Map<String, dynamic>> getClassDataSafe(String classId) async {
    final data = await getClassData(classId);
    return data ?? {}; // إن لم يوجد الصف نعيد خريطة فارغة
  }
  // جلب جميع درجات الطالب لجميع المواد في فصل معين (اختياري، للاستخدام المستقبلي)
  Future<List<Map<String, dynamic>>> getAllStudentGrades(
      String studentId, String classId, int year, String semester) async {
    final subjects = await getStudentSubjects(classId);
    final grades = await _api.get('grades', filters: {
      'student_id': studentId,
      'academic_year': year,
      'semester': semester,
    });
    final subjectMap = {for (var s in subjects) s['id']: s['name']};
    return grades.map((g) {
      g['subject_name'] = subjectMap[g['subject_id']] ?? 'غير معروف';
      return g;
    }).toList();
  }
}
