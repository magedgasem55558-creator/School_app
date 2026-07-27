import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mosque_app/screens/quran_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ استيراد الصفحات المطلوبة
import 'yasser_dossari_page.dart';
import 'hisn_el_muslim_page.dart';
import 'hadith_search_page.dart';

import '../services/firebase_service.dart';
import '../models/mosque_models.dart';
import 'login_screen.dart';
import 'my_children_screen.dart';
import 'leaderboard_screen.dart';
import 'donate_screen.dart';
import 'qibla_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // دالة فتح واتساب للتواصل مع المطور
  void _openWhatsApp(BuildContext context) async {
    const phone = '967776503890'; // رقم واتساب مع مفتاح اليمن
    const message = 'السلام عليكم، أود الاستفسار عن تطبيق المسجد أو طلب نسخة لمسجدنا.';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(color: const Color(0xFF1A002D)),
          Container(color: Colors.black.withOpacity(0.6)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("مرحباً بك في مسجدنا",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 15),
                  const AutoPrayerCountdownGlass(),
                  const SizedBox(height: 12),
                  const RemembranceCarousel(),
                  const SizedBox(height: 15),
                  _buildInfoRow(service),
                  const SizedBox(height: 12),
                  _buildUpcomingLecture(),
                  const SizedBox(height: 30),
                  const Text("أقسام المسجد",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _buildGridItem(context, "المتصدرون", Icons.emoji_events, Colors.amberAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                      }),
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _buildGridItem(context, "أبنائي", Icons.family_restroom, Colors.tealAccent, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyChildrenScreen()));
                            });
                          } else {
                            return _buildGridItem(context, "دخول الآباء", Icons.lock_outline, Colors.blueAccent, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            });
                          }
                        },
                      ),
                      _buildGridItem(context, "تبرع للمسجد", Icons.favorite, Colors.pinkAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DonateScreen()));
                      }),
                      _buildGridItem(context, "القرآن الكريم", Icons.menu_book, Colors.purpleAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()));
                      }),
                      // ✅ البطاقات الجديدة المضافة
                      _buildGridItem(context, "المصحف الصوتي", Icons.headset, Colors.lightBlueAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const YasserDossariQuranPage()));
                      }),
                      _buildGridItem(context, "حصن المسلم", Icons.shield, Colors.lightGreenAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HisnElMuslimPage()));
                      }),
                      _buildGridItem(context, "صحة الحديث", Icons.search_outlined, Colors.orangeAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithSearchPage()));
                      }),
                      _buildGridItem(context, "القبلة", Icons.explore, Colors.redAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblahPage()));


                      }),
                    ],
                  ),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => FirebaseAuth.instance.signOut(),
                              icon: const Icon(Icons.logout, color: Colors.white54),
                              label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white54)),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // ✅ زر التواصل مع المطور
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => _openWhatsApp(context),
                        icon: const Icon(Icons.developer_mode, color: Colors.tealAccent),
                        label: const Text(
                          "انقر هنا للتواصل مع المطور\nأو لطلب نسخة لمسجدك",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── الخطبة والفعالية عمودياً ─────
  Widget _buildInfoRow(FirebaseService service) {
    return StreamBuilder<NextKhutba>(
      stream: service.streamNextKhutba(),
      builder: (context, khutbaSnapshot) {
        if (khutbaSnapshot.connectionState == ConnectionState.waiting) {
          return _buildGlassCard(
            child: const ListTile(title: Text("جاري جلب الخطبة...", style: TextStyle(color: Colors.white54))),
          );
        }
        final khutba = khutbaSnapshot.data;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('next_event')
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return _buildKhutbaCard(khutba);
            }
            if (eventSnapshot.hasError) {
              debugPrint('خطأ في جلب الفعالية: ${eventSnapshot.error}');
              return _buildKhutbaCard(khutba);
            }
            if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
              return _buildKhutbaCard(khutba);
            }

            final eventData = eventSnapshot.data!.data() as Map<String, dynamic>?;
            if (eventData == null || (eventData['title'] as String? ?? '').isEmpty) {
              return _buildKhutbaCard(khutba);
            }

            return Column(
              children: [
                _buildKhutbaCard(khutba),
                const SizedBox(height: 10),
                _buildEventCard(eventData),
              ],
            );
          },
        );
      },
    );
  }

  // ───── المحاضرة القادمة ─────
  Widget _buildUpcomingLecture() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lectures').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          debugPrint('خطأ في جلب المحاضرات: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        List<Map<String, dynamic>> upcoming = [];
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timeStr = data['time'] as String?;
          if (timeStr != null) {
            final time = DateTime.tryParse(timeStr);
            if (time != null && time.isAfter(now)) {
              data['id'] = doc.id;
              upcoming.add(data);
            }
          }
        }

        if (upcoming.isEmpty) {
          return const SizedBox.shrink();
        }

        upcoming.sort((a, b) => DateTime.parse(a['time']).compareTo(DateTime.parse(b['time'])));
        final lecture = upcoming.first;

        return _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book, color: Colors.purpleAccent, size: 28),
              ),
              title: const Text("محاضرة قادمة",
                  style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture['title'] ?? 'محاضرة',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (lecture['speaker'] != null && (lecture['speaker'] as String).isNotEmpty)
                    Text("المحاضر: ${lecture['speaker']}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _formatLectureTime(lecture['time']),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
            ),
          ),
        );
      },
    );
  }

  String _formatLectureTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return isoTime;
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildKhutbaCard(NextKhutba? khutba) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.mic_external_on, color: Colors.tealAccent, size: 28),
          ),
          title: const Text("خطبة الجمعة القادمة",
              style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(khutba?.title ?? "لم يتم تحديد العنوان",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("الخطيب: ${khutba?.imam ?? 'غير محدد'}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'فعالية';
    final location = event['location'] ?? '';
    String? timeStr = event['time'] as String?;
    if (timeStr == null || timeStr.isEmpty) {
      timeStr = event['date'] as String?;
    }
    String dateStr = '';
    if (timeStr != null && timeStr.isNotEmpty) {
      dateStr = _formatLectureTime(timeStr);
    } else {
      final lastUpdated = event['lastUpdated'] as Timestamp?;
      if (lastUpdated != null) {
        final dt = lastUpdated.toDate();
        dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
      }
    }

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.event, color: Colors.orangeAccent, size: 28),
          ),
          title: const Text("فعالية قادمة",
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (location.isNotEmpty)
                Text("المكان: $location", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              if (dateStr.isNotEmpty)
                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

// ───── ويدجت الأذكار المتغيرة ─────
class RemembranceCarousel extends StatefulWidget {
  const RemembranceCarousel({super.key});

  @override
  State<RemembranceCarousel> createState() => _RemembranceCarouselState();
}

class _RemembranceCarouselState extends State<RemembranceCarousel> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _remembrances = [
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _remembrances.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.format_quote, color: Colors.amberAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Text(
                _remembrances[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.format_quote, color: Colors.amberAccent, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── عداد الصلاة مع إصلاح فجر الغد ───
class AutoPrayerCountdownGlass extends StatefulWidget {
  const AutoPrayerCountdownGlass({super.key});

  @override
  State<AutoPrayerCountdownGlass> createState() => _AutoPrayerCountdownGlassState();
}

class _AutoPrayerCountdownGlassState extends State<AutoPrayerCountdownGlass> {
  String _nextPrayerName = "جاري الحساب...";
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPrayerLogic();
  }

  Future<void> _initPrayerLogic() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      Position position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final prayerTimes = PrayerTimes.today(coordinates, params);
        final next = prayerTimes.nextPrayer();

        if (mounted) {
          setState(() {
            if (next != Prayer.none) {
              _nextPrayerName = _translatePrayer(next);
              _timeLeft = prayerTimes.timeForPrayer(next)!.difference(DateTime.now());
            } else {
              // حساب فجر الغد
              _nextPrayerName = "الفجر";
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              final tomorrowDate = DateComponents.from(tomorrow);
              final tomorrowTimes = PrayerTimes(coordinates, tomorrowDate, params);
              _timeLeft = tomorrowTimes.fajr.difference(DateTime.now());
            }
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _nextPrayerName = "خطأ في تحديد الموقع");
    }
  }

  String _translatePrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return "الفجر";
      case Prayer.dhuhr: return "الظهر";
      case Prayer.asr: return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha: return "العشاء";
      default: return "الصلاة";
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Colors.tealAccent, size: 18),
              const SizedBox(width: 8),
              Text("المتبقي لصلاة $_nextPrayerName",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timePart(_timeLeft.inHours.toString().padLeft(2, '0'), "ساعة"),
              _buildDivider(),
              _timePart((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), "دقيقة"),
              _buildDivider(),
              _timePart((_timeLeft.inSeconds % 60).toString().padLeft(2, '0'), "ثانية"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timePart(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10).copyWith(bottom: 15),
    child: const Text(":", style: TextStyle(color: Colors.tealAccent, fontSize: 24)),
  );
}
