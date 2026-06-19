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

  // حالة الرحلة: active أو ended
  String _tripStatus = 'active'; // افتراضي نشط

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
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
        final points = await _driverService.getRecentLocations(driver['id']);

        if (mounted) {
          final allPoints = points.map((p) => LatLng(
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          )).toList();

          // تجميع النقاط حسب الرحلة الحالية (النقاط التي لا تزيد الفجوة بينها عن 30 دقيقة)
          final List<LatLng> currentTripPoints = _getCurrentTripPoints(allPoints, points);

          // تحديد حالة الرحلة: إذا مر أكثر من 30 دقيقة على آخر نقطة، فهي منتهية
          bool isEnded = false;
          if (points.isNotEmpty) {
            final lastTimestamp = DateTime.parse(points.last['timestamp']);
            final diff = DateTime.now().difference(lastTimestamp).inMinutes;
            isEnded = diff > 30;
          }

          setState(() {
            _driver = driver;
            _routePoints = currentTripPoints;
            _tripStatus = isEnded ? 'ended' : 'active';
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
        final gap = previous.difference(current).inMinutes.abs();

        if (gap <= 30) {
          trip.insert(0, allPoints[i]);
        } else {
          break; // فجوة زمنية كبيرة، توقف
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
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.school.app',
                              ),
                              // خط المسار
                              if (_routePoints.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4,
                                      color: Colors.indigo,
                                    ),
                                  ],
                                ),
                              // علامات البداية والنهاية
                              if (_routePoints.isNotEmpty)
                                MarkerLayer(
                                  markers: [
                                    // 🟢 بداية الرحلة
                                    _buildStartMarker(),
                                    // 🔴 نهاية الرحلة (إذا انتهت) أو 🟠 الموقع الحي (إذا نشطة)
                                    _buildEndOrLiveMarker(),
                                  ],
                                ),
                            ],
                          ),
                          // بطاقة حالة الرحلة
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
    final isActive = _tripStatus == 'active';
    return Card(
      color: isActive ? Colors.orange.withOpacity(0.9) : Colors.green.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? Icons.directions_bus : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isActive ? 'الرحلة نشطة الآن' : 'انتهت الرحلة',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildStartMarker() {
    return Marker(
      point: _routePoints.first,
      width: 80,
      height: 50,
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
          Text('انطلاق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700], backgroundColor: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Marker _buildEndOrLiveMarker() {
    final isActive = _tripStatus == 'active';
    final color = isActive ? Colors.orange : Colors.red;
    final icon = isActive ? Icons.directions_bus : Icons.flag_circle;
    final label = isActive ? 'الآن' : 'النهاية';

    return Marker(
      point: _routePoints.last,
      width: 80,
      height: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color[700], backgroundColor: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }
}
