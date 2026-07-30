import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mosque_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotificationToParent(String parentId, String studentName, String activity) async {
  // 1. جلب توكن ولي الأمر من Firestore
  var userDoc = await FirebaseFirestore.instance.collection('users').doc(parentId).get();
  String? parentToken = userDoc.data()?['fcmToken'];

  if (parentToken == null) return;

  // 2. إرسال الطلب لـ Firebase Messaging API
  // ملاحظة: يفضل تنفيذ هذه الخطوة عبر Cloud Functions للأمان، ولكن هذه هي الطريقة المباشرة
  try {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY', // تجده في إعدادات مشروع Firebase
      },
      body: jsonEncode({
        'to': parentToken,
        'notification': {
          'title': 'تحديث جديد لـ $studentName',
          'body': 'تم رصد بيانات جديدة: $activity',
          'sound': 'default',
        },
        'data': {
          'type': 'data_entry',
          'studentId': '123',
        },
      }),
    );
  } catch (e) {
    print("Error sending notification: $e");
  }
}
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. جلب الفعالية القادمة
  Stream<NextEvent> streamNextEvent() {
    return _db.collection('settings').doc('next_event').snapshots().map((doc) {
      return NextEvent.fromFirestore(doc.data()!);
    });
  }

  // 2. جلب خطبة الجمعة
  Stream<NextKhutba> streamNextKhutba() {
    return _db.collection('settings').doc('next_khutba').snapshots().map((doc) {
      return NextKhutba.fromFirestore(doc.data()!);
    });
  }

  // 3. جلب أوقات الصلاة
  Stream<Map<String, dynamic>> streamPrayerTimes() {
    return _db.collection('prayer_times').doc('today').snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  // 4. جلب قائمة الأبناء لولي أمر محدد
  Stream<List<Map<String, dynamic>>> streamMyChildren(String parentUid) {
    return _db
        .collection('students')
        .where('parentId', isEqualTo: parentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                "id": doc.id,
                ...doc.data(),
              };
            }).toList());
  }

  // 5. جلب المتصدرين بناءً على "عدد الأسطر" لضمان العدالة
  Stream<List<Map<String, dynamic>>> streamTopStudentsByLines() {
    return _db
        .collection('students')
        .orderBy('totalLines', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              "id": doc.id,
              ...doc.data(),
            }).toList());
  }
}