import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';
import '../theme.dart'; // استيراد AppTheme

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

  String _tripStatus = 'active';
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
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

          final List<LatLng> currentTripPoints = _getCurrentTripPoints(allPoints, points);

          String status = 'active';
          if (points.isNotEmpty) {
            final lastTimestamp = DateTime.parse(points.last['timestamp']);
            final diffInSeconds = DateTime.now().difference(lastTimestamp).inSeconds;
            status = diffInSeconds > 60 ? 'recently_ended' : 'active';
          } else {
            status = 'no_data';
          }

          setState(() {
            _driver = driver;
            _routePoints = currentTripPoints;
            _tripStatus = status;
            _isLoading = false;
          });

          if (_routePoints.isNotEmpty && _tripStatus == 'active') {
            _mapController?.move(_routePoints.last, 18);
          }
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
          trip.insert(0, allPoints[i]);
        } else {
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
        backgroundColor: AppTheme.primaryColor,
        title: Text('مسار ${widget.studentName}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'تحديث المسار',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _driver == null
              ? Center(child: _buildNoDriver())
              : _routePoints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('لا توجد إحداثيات مسجلة بعد',
                              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Text('بانتظار بدء الرحلة...',
                              style: TextStyle(fontSize: 14, color: Colors.grey[400])),
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
                                mapController: _mapController!,
                                options: MapOptions(
                                  initialCenter: _routePoints.isNotEmpty
                                      ? _routePoints.last
                                      : _attaqCenter,
                                  initialZoom: 18,
                                  minZoom: 5,
                                  maxZoom: 19,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.school.app',
                                  ),
                                  if (_routePoints.length > 1)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _routePoints,
                                          strokeWidth: 6,
                                          color: AppTheme.primaryColor,
                                          borderStrokeWidth: 2,
                                          borderColor: Colors.white,
                                        ),
                                      ],
                                    ),
                                  if (_routePoints.isNotEmpty)
                                    MarkerLayer(markers: _buildMarkers()),
                                ],
                              ),
                              Positioned(
                                top: 10, left: 10, right: 10,
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
        Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('لا يوجد سائق مرتبط بهذا الطالب',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: const Icon(Icons.person, size: 36, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_driver!['name'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('لوحة: ${_driver!['plate_number'] ?? 'غير محدد'}',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Text('نوع: ${_driver!['vehicle_type'] ?? 'غير محدد'}',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatusCard() {
    Color bgColor;
    String text;
    IconData icon;

    switch (_tripStatus) {
      case 'active':
        bgColor = AppTheme.success;
        icon = Icons.directions_bus;
        text = '🚌 الرحلة نشطة الآن';
        break;
      case 'recently_ended':
        bgColor = AppTheme.error;
        icon = Icons.flag_circle;
        text = '🏁 انتهت الرحلة';
        break;
      default:
        bgColor = AppTheme.textSecondary;
        icon = Icons.info;
        text = '⏳ في الانتظار...';
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
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_routePoints.length >= 2) {
      // 🟢 نقطة البداية
      markers.add(Marker(
        point: _routePoints.first,
        width: 80, height: 55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withOpacity(0.3),
                border: Border.all(color: AppTheme.success, width: 2),
              ),
              child: const Icon(Icons.flag_circle, color: AppTheme.success, size: 28),
            ),
            const SizedBox(height: 2),
            Text('انطلاق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: AppTheme.success, backgroundColor: Colors.white.withOpacity(0.8))),
          ],
        ),
      ));

      // 🟠/🔴 نقطة النهاية
      final isActive = _tripStatus == 'active';
      final endColor = isActive ? AppTheme.warning : AppTheme.error;
      final endIcon = isActive ? Icons.directions_bus : Icons.flag_circle;
      final endLabel = isActive ? 'الآن' : 'النهاية';

      markers.add(Marker(
        point: _routePoints.last,
        width: 80, height: 55,
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
            Text(endLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: endColor, backgroundColor: Colors.white.withOpacity(0.8))),
          ],
        ),
      ));
    } else if (_routePoints.length == 1) {
      markers.add(Marker(
        point: _routePoints.first,
        width: 80, height: 55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.3),
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
              child: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 2),
            Text('الآن', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor, backgroundColor: Colors.white.withOpacity(0.8))),
          ],
        ),
      ));
    }

    return markers;
  }
}
