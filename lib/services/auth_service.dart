import '../models/student.dart';
import 'api_service.dart';

class AuthService {
  // ---------- Singleton ----------
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal(); // مُنشئ خاص

  final ApiService _api = ApiService();
  List<Student> _children = [];
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  List<Student> get children => _children;

  // تسجيل الدخول برقم الجوال فقط
  Future<({bool success, String message})> login(String phone) async {
    if (phone.isEmpty) {
      return (success: false, message: 'الرجاء إدخال رقم الجوال');
    }

    try {
      final students = await _api.get('students', filters: {'parent_phone': phone});
      if (students.isEmpty) {
        return (success: false, message: 'لا يوجد أبناء مرتبطون بهذا الرقم');
      }

      _children = students.map((s) => Student.fromJson(s)).toList();
      _isLoggedIn = true;
      return (success: true, message: 'مرحباً، لديك ${_children.length} أبناء');
    } catch (e) {
      return (success: false, message: 'حدث خطأ أثناء الاتصال: $e');
    }
  }

  void logout() {
    _children = [];
    _isLoggedIn = false;
  }
}