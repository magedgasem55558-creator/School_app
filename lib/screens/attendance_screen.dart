import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/parent_service.dart';
import '../widgets/gradient_app_bar.dart';

class AttendanceScreen extends StatefulWidget {
  final String studentId;
  const AttendanceScreen({super.key, required this.studentId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final ParentService _parentService = ParentService();

  String viewMode = 'daily';
  String currentMonthName = '';
  List<Map<String, dynamic>> monthlyReport = [];
  Map<String, dynamic> attendanceStats = {'present': 0, 'absent': 0, 'late': 0};

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, dynamic> monthlySummary = {};

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  late AnimationController _pulseController;

  final List<int> availableYears =
      List.generate(6, (i) => DateTime.now().year - 2 + i);

  static const List<Map<String, dynamic>> monthsList = [
    {'value': 1, 'name': 'يناير'}, {'value': 2, 'name': 'فبراير'}, {'value': 3, 'name': 'مارس'},
    {'value': 4, 'name': 'أبريل'}, {'value': 5, 'name': 'مايو'}, {'value': 6, 'name': 'يونيو'},
    {'value': 7, 'name': 'يوليو'}, {'value': 8, 'name': 'أغسطس'}, {'value': 9, 'name': 'سبتمبر'},
    {'value': 10, 'name': 'أكتوبر'}, {'value': 11, 'name': 'نوفمبر'}, {'value': 12, 'name': 'ديسمبر'}
  ];

  @override
  void initState() {
    super.initState();
    currentMonthName = DateFormat('MMMM', 'ar').format(DateTime.now());
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    loadAttendance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> loadAttendance() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });
    try {
      if (viewMode == 'daily') {
        await loadDailyAttendance();
      } else {
        await loadMonthlyAttendance();
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

// أضف هذه الدالة داخل الكلاس _AttendanceScreenState
String _formatDate(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

Future<void> loadDailyAttendance() async {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);
  
  final start = _formatDate(startDate);
  final end = _formatDate(endDate);
  
  debugPrint('✅ جلب الحضور اليومي من $start إلى $end');

  final records = await _parentService.getAttendance(widget.studentId, start, end);

  final Map<String, String> recordMap = {};
  for (final r in records) {
    // تأكد من أن التاريخ في السجلات هو أيضاً بالتنسيق الصحيح
    final date = r['date'].toString().substring(0, 10);
    recordMap[date] = r['status'];
  }

  final daysInMonth = endDate.day;
  final List<Map<String, dynamic>> report = [];
  int present = 0, absent = 0, late = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(now.year, now.month, day);
    final dateStr = _formatDate(date);
    final status = recordMap[dateStr] ?? 'غير مسجل';
    String icon = '❓';
    if (status == 'present') { icon = '✅'; present++; }
    else if (status == 'absent') { icon = '❌'; absent++; }
    else if (status == 'late') { icon = '⏰'; late++; }
    report.add({'day': day, 'date': dateStr, 'status': status, 'icon': icon});
  }

  setState(() {
    monthlyReport = report;
    attendanceStats = {'present': present, 'absent': absent, 'late': late};
  });
}

Future<void> loadMonthlyAttendance() async {
  final year = selectedYear;
  final month = selectedMonth;
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);
  
  final start = _formatDate(startDate);
  final end = _formatDate(endDate);
  
  debugPrint('✅ جلب الحضور الشهري من $start إلى $end');

  final records = await _parentService.getAttendance(widget.studentId, start, end);
  int present = 0, absent = 0, late = 0;
  for (final r in records) {
    if (r['status'] == 'present') present++;
    else if (r['status'] == 'absent') absent++;
    else if (r['status'] == 'late') late++;
  }
  double rate = (present + absent + late) > 0 ? (present / (present + absent + late)) * 100 : 0;

  setState(() {
    monthlySummary = {
      'present': present,
      'absent': absent,
      'late': late,
      'total_days': present + absent + late,
      'attendance_rate': rate,
    };
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الحضور - ${viewMode == 'daily' ? currentMonthName : '${getMonthName(selectedMonth)} $selectedYear'}',
        actions: [
          IconButton(
            icon: Icon(viewMode == 'daily' ? Icons.calendar_view_month : Icons.grid_view),
            onPressed: () {
              setState(() {
                viewMode = viewMode == 'daily' ? 'monthly' : 'daily';
                loadAttendance();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0221), Color(0xFF2A0A5C), Color(0xFF4A148C)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(painter: StarFieldPainter(), size: Size.infinite),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            else if (hasError)
              _buildErrorView()
            else if (viewMode == 'daily')
              _buildDailyView()
            else
              _buildMonthlyView(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFFD700), size: 48),
          const SizedBox(height: 16),
          const Text('تعذر تحميل بيانات الحضور', style: TextStyle(color: Colors.white70, fontSize: 18)),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMessage, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: loadAttendance,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }


  Widget _buildDailyView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: monthlyReport.length,
              itemBuilder: (context, index) {
                final day = monthlyReport[index];
                Color bg, textColor, borderColor;
                switch (day['status']) {
                  case 'present':
                    bg = const Color(0xFF00E676).withOpacity(0.15);
                    textColor = const Color(0xFF00E676);
                    borderColor = const Color(0xFF00E676).withOpacity(0.5);
                    break;
                  case 'absent':
                    bg = const Color(0xFFFF1744).withOpacity(0.15);
                    textColor = const Color(0xFFFF1744);
                    borderColor = const Color(0xFFFF1744).withOpacity(0.5);
                    break;
                  case 'late':
                    bg = const Color(0xFFFFD700).withOpacity(0.15);
                    textColor = const Color(0xFFFFD700);
                    borderColor = const Color(0xFFFFD700).withOpacity(0.5);
                    break;
                  default:
                    bg = Colors.white.withOpacity(0.05);
                    textColor = Colors.white38;
                    borderColor = Colors.white24;
                }
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [BoxShadow(color: textColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day['day']}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(day['icon'] ?? '', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // محددات السنة والشهر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildYearDropdown(),
              const SizedBox(width: 20),
              _buildMonthDropdown(),
            ],
          ),
          const SizedBox(height: 20),
          // بطاقة الملخص
          _buildMonthlySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('حاضر', attendanceStats['present'], const Color(0xFF00E676), '✅'),
        _buildStatCard('غائب', attendanceStats['absent'], const Color(0xFFFF1744), '❌'),
        _buildStatCard('متأخر', attendanceStats['late'], const Color(0xFFFFD700), '⏰'),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, String icon) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2 + _pulseController.value * 0.1),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: DropdownButton<int>(
        value: selectedYear,
        dropdownColor: const Color(0xFF2A0A5C),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFFFD700)),
        underline: const SizedBox(),
        items: availableYears.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => selectedYear = v);
            loadAttendance();
          }
        },
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: DropdownButton<int>(
        value: selectedMonth,
        dropdownColor: const Color(0xFF2A0A5C),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFFFD700)),
        underline: const SizedBox(),
        items: monthsList.map((m) => DropdownMenuItem<int>(
      value: m['value'] as int,
      child: Text(m['name'] as String),
    )).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => selectedMonth = v);
            loadAttendance();
          }
        },
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final data = monthlySummary;
    final present = data['present'] ?? 0;
    final absent = data['absent'] ?? 0;
    final late = data['late'] ?? 0;
    final total = data['total_days'] ?? 0;
    final rate = data['attendance_rate'] ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('إحصائيات الشهر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _summaryRow('عدد أيام الحضور', '$present', const Color(0xFF00E676)),
          _summaryRow('عدد أيام الغياب', '$absent', const Color(0xFFFF1744)),
          _summaryRow('عدد مرات التأخير', '$late', const Color(0xFFFFD700)),
          const Divider(color: Color(0xFFFFD700), height: 24),
          _summaryRow('إجمالي الأيام المسجلة', '$total', Colors.white),
          _summaryRow('نسبة الحضور', '${rate.toStringAsFixed(1)}%', const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  String getMonthName(int month) {
    return monthsList.firstWhere((m) => m['value'] == month)['name'];
  }
}

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42);
    for (int i = 0; i < 120; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}