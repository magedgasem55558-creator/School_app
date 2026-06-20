import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';

class BusTrackingScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const BusTrackingScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final DriverService _driverService = DriverService();
  Map<String, dynamic>? _driver;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  static const LatLng _attaqCenter = LatLng(14.5376, 46.8319); // عتق

  // حالة الرحلة
  String _tripStatus = 'active'; // 'active', 'recently_ended', 'ended'
  String? _lastPointTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    // ⏱️ تحديث كل 3 ثوانٍ ليتوافق مع مدة إرسال الإحداثيات
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final driver = await _driverService.getDriverForStudent(widget.studentId);

      if (driver != null) {
        // جلب كل الإحداثيات خلال آخر ساعة
        final points = await _driverService.getRecentLocations(driver['id']);

        if (mounted) {
          final allPoints = points.map((p) => LatLng(
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          )).toList();

          // تجميع نقاط الرحلة الحالية فقط
          final List<LatLng> currentTripPoints = _getCurrentTripPoints(allPoints, points);

          // تحديد حالة الرحلة بناءً على آخر نقطة
          String status = 'active';
          if (points.isNotEmpty) {
            final lastTimestamp = DateTime.parse(points.last['timestamp']);
            final diffInSeconds = DateTime.now().difference(lastTimestamp).inSeconds;
            
            if (diffInSeconds > 60) {
              // مر أكثر من دقيقة على آخر نقطة → الرحلة منتهية
              status = 'recently_ended';
            } else {
              // أقل من دقيقة → الرحلة نشطة
              status = 'active';
            }
            
            _lastPointTime = '${diffInSeconds ~/ 60}:${(diffInSeconds % 60).toString().padLeft(2, '0')}';
          } else {
            status = 'no_data';
          }

          setState(() {
            _driver = driver;
            _routePoints = currentTripPoints;
            _tripStatus = status;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _driver = null;
            _routePoints = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('❌ خطأ جلب المسار: $e');
    }
  }

  /// إرجاع نقاط الرحلة الحالية فقط (متجاورة زمنياً)
  List<LatLng> _getCurrentTripPoints(
    List<LatLng> allPoints,
    List<Map<String, dynamic>> rawPoints,
  ) {
    if (allPoints.isEmpty) return [];

    List<LatLng> trip = [];
    for (int i = allPoints.length - 1; i >= 0; i--) {
      if (trip.isEmpty) {
        trip.add(allPoints[i]);
      } else {
        final current = DateTime.parse(rawPoints[i]['timestamp']);
        final previous = DateTime.parse(rawPoints[i + 1]['timestamp']);
        final gap = previous.difference(current).inSeconds.abs();

        if (gap <= 60) {
          // فجوة أقل من دقيقة → نفس الرحلة
          trip.insert(0, allPoints[i]);
        } else {
          // فجوة كبيرة → رحلة جديدة
          break;
        }
      }
    }
    return trip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مسار ${widget.studentName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث المسار',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _driver == null
              ? Center(child: _buildNoDriver())
              : _routePoints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('لا توجد إحداثيات مسجلة بعد', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('بانتظار بدء الرحلة...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildDriverInfo(),
                        Expanded(
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: _routePoints.isNotEmpty
                                      ? _routePoints.last
                                      : _attaqCenter,
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.school.app',
                                  ),
                                  // 🔵 خط المسار
                                  if (_routePoints.length > 1)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _routePoints,
                                          strokeWidth: 5,
                                          color: Colors.indigo,
                                        ),
                                      ],
                                    ),
                                  // علامات البداية والنهاية
                                  if (_routePoints.isNotEmpty)
                                    MarkerLayer(
                                      markers: _buildMarkers(),
                                    ),
                                ],
                              ),
                              // بطاقة الحالة
                              Positioned(
                                top: 10,
                                left: 10,
                                right: 10,
                                child: _buildTripStatusCard(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildNoDriver() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('لا يوجد سائق مرتبط بهذا الطالب', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.withOpacity(0.2), Colors.indigo.withOpacity(0.05)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigo.withOpacity(0.1)),
            child: const Icon(Icons.person, size: 36, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_driver!['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('لوحة: ${_driver!['plate_number'] ?? 'غير محدد'}'),
                Text('نوع: ${_driver!['vehicle_type'] ?? 'غير محدد'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatusCard() {
    Color bgColor;
    IconData icon;
    String text;

    switch (_tripStatus) {
      case 'active':
        bgColor = Colors.orange.withOpacity(0.9);
        icon = Icons.directions_bus;
        text = '🚌 الرحلة نشطة الآن';
        break;
      case 'recently_ended':
        bgColor = Colors.red.withOpacity(0.9);
        icon = Icons.flag_circle;
        text = '🏁 انتهت الرحلة';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.9);
        icon = Icons.info;
        text = 'في الانتظار...';
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    if (_routePoints.length >= 2) {
      // 🟢 نقطة البداية (دائماً)
      markers.add(
        Marker(
          point: _routePoints.first,
          width: 80,
          height: 55,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.3),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Icon(Icons.flag_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(height: 2),
              Text(
                'انطلاق',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700], backgroundColor: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );

      // 🔴 نقطة النهاية (إذا انتهت) أو 🟠 الموقع الحي (إذا نشطة)
      final isActive = _tripStatus == 'active';
      final endColor = isActive ? Colors.orange : Colors.red;
      final endIcon = isActive ? Icons.directions_bus : Icons.flag_circle;
      final endLabel = isActive ? 'الآن' : 'النهاية';

      markers.add(
        Marker(
          point: _routePoints.last,
          width: 80,
          height: 55,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: endColor.withOpacity(0.3),
                  border: Border.all(color: endColor, width: 2),
                ),
                child: Icon(endIcon, color: endColor, size: 28),
              ),
              const SizedBox(height: 2),
              Text(
                endLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: endColor[700], backgroundColor: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    } else if (_routePoints.length == 1) {
      // نقطة واحدة فقط
      markers.add(
        Marker(
          point: _routePoints.first,
          width: 80,
          height: 55,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.3),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(Icons.location_on, color: Colors.orange, size: 28),
              ),
              const SizedBox(height: 2),
              Text(
                'الآن',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[700], backgroundColor: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }
}
