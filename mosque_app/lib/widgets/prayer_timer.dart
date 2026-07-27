import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class AutoPrayerCountdown extends StatefulWidget {
  const AutoPrayerCountdown({super.key});

  @override
  State<AutoPrayerCountdown> createState() => _AutoPrayerCountdownState();
}

class _AutoPrayerCountdownState extends State<AutoPrayerCountdown> {
  String _nextPrayerName = "جاري الحساب...";
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPrayerCalculation();
  }

  Future<void> _initPrayerCalculation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _nextPrayerName = "الإذن مرفوض");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final prayerTimes = PrayerTimes.today(myCoordinates, params);
        final nextPrayer = prayerTimes.nextPrayer();
        
        if (nextPrayer != Prayer.none) {
          final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
          if (mounted) {
            setState(() {
              _nextPrayerName = _getArabicName(nextPrayer);
              _timeLeft = nextPrayerTime!.difference(DateTime.now());
              _loading = false;
            });
          }
        } else {
          // جميع الصلوات انتهت، نحسب فجر الغد
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowDate = DateComponents.from(tomorrow);
          // نعيد استخدام نفس المعاملات أو ننشئ جديدًا
          final tomorrowParams = CalculationMethod.umm_al_qura.getParameters()
            ..madhab = Madhab.shafi;
          final tomorrowTimes = PrayerTimes(myCoordinates, tomorrowDate, tomorrowParams);

          if (mounted) {
            setState(() {
              _nextPrayerName = "الفجر";
              _timeLeft = tomorrowTimes.fajr.difference(DateTime.now());
              _loading = false;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _nextPrayerName = "خطأ في تحديد الموقع");
    }
  }

  String _getArabicName(Prayer prayer) {
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
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text("المتبقي لصلاة $_nextPrayerName", 
            style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimePart(_timeLeft.inHours.toString().padLeft(2, '0'), "ساعة"),
              _buildDivider(),
              _buildTimePart((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), "دقيقة"),
              _buildDivider(),
              _buildTimePart((_timeLeft.inSeconds % 60).toString().padLeft(2, '0'), "ثانية"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePart(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10).copyWith(bottom: 15),
    child: Text(":", 
      style: TextStyle(
        color: Colors.tealAccent.withOpacity(0.5), 
        fontSize: 24,
      ),
    ),
  );
}