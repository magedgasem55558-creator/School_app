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
      debugPrint('🔍 السائق المُسترجع: $driver');

      if (driver != null) {
        final points = await _driverService.getRecentLocations(driver['id']);
        debugPrint('📍 عدد النقاط: ${points.length}');

        if (mounted) {
          setState(() {
            _driver = driver;
            _routePoints = points.map((p) => LatLng(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            )).toList();
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
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'لا يوجد سائق مرتبط بهذا الطالب',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.withOpacity(0.2),
                            Colors.indigo.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.indigo.withOpacity(0.1),
                            ),
                            child: const Icon(Icons.person, size: 36, color: Colors.indigo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driver!['name'] ?? '',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('لوحة: ${_driver!['plate_number'] ?? 'غير محدد'}'),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(_driver!['vehicle_type'] ?? 'غير محدد'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
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
                          // 🔵 خط المسار
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
                          // 🟢 علامة الانطلاق + 🔴 علامة الوصول
                          if (_routePoints.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                // 🟢 نقطة الانطلاق
                                Marker(
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
                                      Text(
                                        'انطلاق',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                          backgroundColor: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 🔴 نقطة الوصول الحالية
                                Marker(
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
                                          color: Colors.red.withOpacity(0.3),
                                          border: Border.all(color: Colors.red, width: 2),
                                        ),
                                        child: const Icon(Icons.location_on, color: Colors.red, size: 28),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'الآن',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                          backgroundColor: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
