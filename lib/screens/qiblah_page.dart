import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblahPage extends StatefulWidget {
  const QiblahPage({Key? key}) : super(key: key);

  @override
  State<QiblahPage> createState() => _QiblahPageState();
}

class _QiblahPageState extends State<QiblahPage> {
  // إحداثيات الكعبة المشرفة الدقيقة
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  double? _qiblahAngle;
  bool _hasPermission = false;
  bool _isLoading = true;
  String _statusMessage = 'جاري تحديد الموقع وحساب اتجاه القبلة...';

  @override
  void initState() {
    super.initState();
    _initQiblah();
  }

  Future<void> _initQiblah() async {
    // 1. طلب إذن الموقع
    final status = await Permission.location.request();

    if (status.isGranted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'يرجى تفعيل خدمة الموقع (GPS) في الهاتف.';
        });
        return;
      }

      try {
        // 2. جلب موقع المستخدم بدقة عالية
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 3. حساب زاوية القبلة بالنسبة للشمال الحقيقي
        double qiblah = _calculateQiblahAngle(position.latitude, position.longitude);

        setState(() {
          _qiblahAngle = qiblah;
          _hasPermission = true;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'حدث خطأ أثناء تحديد إحداثيات الموقع.';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = 'يتطلب تحديد القبلة السماح لصلاحية الموقع.';
      });
    }
  }

  // المعادلة الرياضية الدقيقة لحساب اتجاه القبلة من أي مكان على الأرض
  double _calculateQiblahAngle(double userLat, double userLng) {
    double userLatRad = _degToRad(userLat);
    double userLngRad = _degToRad(userLng);
    double kaabaLatRad = _degToRad(_kaabaLat);
    double kaabaLngRad = _degToRad(_kaabaLng);

    double deltaLng = kaabaLngRad - userLngRad;

    double y = math.sin(deltaLng);
    double x = math.cos(userLatRad) * math.tan(kaabaLatRad) -
        math.sin(userLatRad) * math.cos(deltaLng);

    double qiblahRad = math.atan2(y, x);
    double qiblahDeg = _radToDeg(qiblahRad);

    return (qiblahDeg + 360) % 360;
  }

  double _degToRad(double degree) => degree * (math.pi / 180.0);
  double _radToDeg(double radian) => radian * (180.0 / math.pi);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : !_hasPermission
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: _initQiblah,
                          child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('خطأ في قراءة حساس البوصلة بالجهاز'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }

                    // اتجاه رأس الهاتف بالنسبة للشمال
                    double? heading = snapshot.data?.heading;

                    if (heading == null) {
                      return const Center(child: Text('جهازك لا يحتوي على حساس البوصلة (Magnetometer)'));
                    }

                    // الفرق بين اتجاه الهاتف واتجاه القبلة
                    double headingRad = _degToRad(heading);
                    double qiblahRad = _degToRad(_qiblahAngle!);
                    double directionToQiblah = qiblahRad - headingRad;

                    // التحقق مما إذا كان الهاتف متجهاً للقبلة بدقة (هامش خطأ 3 درجات)
                    double angleDifference = ((_radToDeg(directionToQiblah) + 180) % 360) - 180;
                    bool isFacingQiblah = angleDifference.abs() < 3.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFacingQiblah ? 'أنت تتجه نحو القبلة تماماً 🕋' : 'قم بتدوير الهاتف نحو السهم',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isFacingQiblah ? Colors.green.shade700 : Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // خلفية البوصلة (الدائرة الخارجية)
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.teal.withOpacity(0.05),
                                  border: Border.all(
                                    color: isFacingQiblah ? Colors.green : Colors.teal,
                                    width: 4,
                                  ),
                                ),
                              ),
                              // إبرة البوصلة المتحركة الموجهة نحو القبلة
                              Transform.rotate(
                                angle: directionToQiblah,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.navigation_rounded,
                                      size: 100,
                                      color: isFacingQiblah ? Colors.green.shade700 : Colors.teal,
                                    ),
                                    const SizedBox(height: 10),
                                    const Icon(
                                      Icons.mosque_rounded,
                                      size: 32,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'زاوية القبلة: ${_qiblahAngle!.toStringAsFixed(1)}°',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
