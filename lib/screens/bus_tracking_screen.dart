import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';
import '../theme.dart';

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

  List<LatLng> _getCurrentTripPoints(List<LatLng> allPoints, List<Map<String, dynamic>> rawPoints) {
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
      appBar: AppBar(title: Text('مسار ${widget.studentName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _driver == null
              ? _buildNoDriver()
              : _routePoints.isEmpty
                  ? const Center(
                      child: Text('لا توجد إحداثيات مسجلة بعد',
                          style: TextStyle(color: AppTheme.textSecondary)),
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
                                  initialCenter: _routePoints.last,
                                  initialZoom: 18,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  ),
                                  if (_routePoints.length > 1)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _routePoints,
                                          strokeWidth: 6,
                                          color: Colors.blue[800]!,
                                        ),
                                      ],
                                    ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('لا يوجد سائق مرتبط'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.person, size: 36, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_driver!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('لوحة: ${_driver!['plate_number'] ?? ''}'),
                Text('نوع: ${_driver!['vehicle_type'] ?? ''}'),
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
    switch (_tripStatus) {
      case 'active':
        bgColor = AppTheme.success;
        text = '🚌 الرحلة نشطة';
        break;
      case 'recently_ended':
        bgColor = AppTheme.error;
        text = '🏁 انتهت الرحلة';
        break;
      default:
        bgColor = AppTheme.textSecondary;
        text = '⏳ في الانتظار';
    }
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_routePoints.length >= 2) {
      markers.add(Marker(
        point: _routePoints.first,
        width: 80, height: 50,
        child: Column(
          children: [
            const Icon(Icons.flag_circle, color: AppTheme.success, size: 28),
            const Text('انطلاق', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
          ],
        ),
      ));
      final isActive = _tripStatus == 'active';
      final endColor = isActive ? AppTheme.warning : AppTheme.error;
      final endLabel = isActive ? 'الآن' : 'النهاية';
      markers.add(Marker(
        point: _routePoints.last,
        width: 80, height: 50,
        child: Column(
          children: [
            Icon(Icons.directions_bus, color: endColor, size: 28),
            Text(endLabel, style: TextStyle(fontSize: 11, color: endColor)),
          ],
        ),
      ));
    } else if (_routePoints.length == 1) {
      markers.add(Marker(
        point: _routePoints.first,
        width: 80, height: 50,
        child: const Column(
          children: [
            Icon(Icons.location_on, color: AppTheme.primary, size: 28),
            Text('الآن', style: TextStyle(color: AppTheme.primary)),
          ],
        ),
      ));
    }
    return markers;
  }
}