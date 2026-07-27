import 'dart:async'; // <-- ضروري لـ StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const List<String> dhikrList = [
    "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
    "لاَ إِلَهَ إِلاَّ أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
    "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلاَ إِلَهَ إِلاَّ اللَّهُ، وَاللَّهُ أَكْبَرُ",
    "أَسْتَغْفِرُ اللَّهَ الَّذِي لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ",
    "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ",
    "لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ",
    "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
    "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ",
    "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلاً مُتَقَبَّلاً",
    "اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ",
    "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ (مائة مرة)",
    "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
    "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ مَا عَمِلْتُ، وَمِنْ شَرِّ مَا لَمْ أَعْمَلْ",
    "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ نَبِيًّا وَرَسُولاً",
    "يَا حَيُّ يَا قَيُّومُ، بِرَحْمَتِكَ أَسْتَغِيثُ",
  ];

  // ═════════════════════ تهيئة الإشعارات ═════════════════════
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    const dhikrChannel = AndroidNotificationChannel(
      'dhikr_channel', 'أذكار',
      description: 'إشعارات الأذكار',
      importance: Importance.high,
      playSound: false,
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(dhikrChannel);

    await _initFCM();
  }

  // ═════════════════════ FCM ═════════════════════
  static Future<void> _initFCM() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');
      _saveTokenToFirestore(token);

      FirebaseMessaging.onMessage.listen(_showFCMNotification);
    } catch (e) {
      debugPrint('فشل إعداد FCM: $e');
    }
  }

  static void _showFCMNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mosque_channel', 'إشعارات المسجد',
          channelDescription: 'إشعارات تطبيق المسجد',
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  // ✅ الدالة العامة التي يناديها FirebaseMessagingHandler
  static void showLocalNotificationFromMessage(RemoteMessage message) {
    _showFCMNotification(message);
  }

  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ═════════════════════ جدولة الأذكار كل نصف ساعة ═════════════════════
  static Future<void> scheduleDhikr() async {
    await _plugin.cancelAll();
    tz.initializeTimeZones();
    final now = DateTime.now();

    for (int totalMinutes = 8 * 60; totalMinutes <= 22 * 60; totalMinutes += 30) {
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      final scheduledDate = tz.TZDateTime.local(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) continue;

      final index = (totalMinutes ~/ 30) % dhikrList.length;
      await _plugin.zonedSchedule(
        totalMinutes,
        'ذكر الله',
        dhikrList[index],
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dhikr_channel', 'أذكار',
            channelDescription: 'أذكار نصف ساعة',
            importance: Importance.high,
            playSound: false,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // ═════════════════════ الاستماع لرصد درجات الأبناء ═════════════════════
  static StreamSubscription? _childrenSub;

  static void startListeningToChildrenGrades(String parentId) {
    _childrenSub?.cancel();
    _childrenSub = FirebaseFirestore.instance
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final newData = change.doc.data()!; // ✅ نضمن أنها ليست null
          final oldPoints = (newData['totalPoints'] ?? 0) as num;
          final newPoints = (newData['totalPoints'] ?? 0) as num;
          final childName = newData['name'] ?? 'الابن';
          if (newPoints > oldPoints) {
            _showGradeNotification(childName, (newPoints - oldPoints).toDouble());
          }
        }
      }
    });
  }

  static void stopListeningToChildrenGrades() {
    _childrenSub?.cancel();
  }

  static void _showGradeNotification(String childName, double addedPoints) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'grades_channel', 'رصد الدرجات',
      description: 'إشعارات رصد الدرجات',
      importance: Importance.high,
      playSound: true,
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    androidPlugin?.createNotificationChannel(channel);

    _plugin.show(
      childName.hashCode + DateTime.now().millisecond,
      'تم إضافة درجة',
      'تم إضافة $addedPoints نقطة لـ $childName',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grades_channel', 'رصد الدرجات',
          channelDescription: 'إشعارات رصد الدرجات',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}