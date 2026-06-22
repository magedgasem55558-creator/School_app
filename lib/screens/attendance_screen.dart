import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/parent_service.dart';
import '../theme.dart';

class AttendanceScreen extends StatefulWidget {
  final String studentId;
  const AttendanceScreen({super.key, required this.studentId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ParentService _parentService = ParentService();

  String viewMode = 'daily'; // 'daily' or 'monthly'
  String currentMonthName = '';
  List<Map<String, dynamic>> dailyReport = [];
  Map<String, dynamic> dailyStats = {'present': 0, 'absent': 0, 'late': 0};

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, dynamic> monthlySummary = {};

  bool isLoading = true;
  String? errorMessage;

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
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
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
        errorMessage = e.toString();
      });
    }
  }

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

    final records = await _parentService.getAttendance(widget.studentId, start, end);
    final Map<String, String> recordMap = {};
    for (final r in records) {
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
      dailyReport = report;
      dailyStats = {'present': present, 'absent': absent, 'late': late};
    });
  }

  Future<void> loadMonthlyAttendance() async {
    final year = selectedYear;
    final month = selectedMonth;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    final records = await _parentService.getAttendance(widget.studentId, start, end);
    int present = 0, absent = 0, late = 0;
    for (final r in records) {
      if (r['status'] == 'present') present++;
      else if (r['status'] == 'absent') absent++;
      else if (r['status'] == 'late') late++;
    }
    double rate = (present + absent + late) > 0
        ? (present / (present + absent + late)) * 100
        : 0;

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
      appBar: AppBar(
        title: Text(
          'الحضور - ${viewMode == 'daily' ? currentMonthName : '${_getMonthName(selectedMonth)} $selectedYear'}',
        ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : viewMode == 'daily'
                  ? _buildDailyView()
                  : _buildMonthlyView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 16),
          const Text('تعذر تحميل بيانات الحضور'),
          if (errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMessage!, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: loadAttendance,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
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
              itemCount: dailyReport.length,
              itemBuilder: (context, index) {
                final day = dailyReport[index];
                Color bg, textColor, borderColor;
                switch (day['status']) {
                  case 'present':
                    bg = AppTheme.success.withOpacity(0.1);
                    textColor = AppTheme.success;
                    borderColor = AppTheme.success.withOpacity(0.3);
                    break;
                  case 'absent':
                    bg = AppTheme.error.withOpacity(0.1);
                    textColor = AppTheme.error;
                    borderColor = AppTheme.error.withOpacity(0.3);
                    break;
                  case 'late':
                    bg = AppTheme.warning.withOpacity(0.1);
                    textColor = AppTheme.warning;
                    borderColor = AppTheme.warning.withOpacity(0.3);
                    break;
                  default:
                    bg = Colors.grey.shade100;
                    textColor = AppTheme.textSecondary;
                    borderColor = Colors.grey.shade300;
                }
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day['day']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildYearDropdown(),
              const SizedBox(width: 20),
              _buildMonthDropdown(),
            ],
          ),
          const SizedBox(height: 20),
          _buildMonthlySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('حاضر', dailyStats['present'], AppTheme.success, '✅'),
        _buildStatCard('غائب', dailyStats['absent'], AppTheme.error, '❌'),
        _buildStatCard('متأخر', dailyStats['late'], AppTheme.warning, '⏰'),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, String icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text('$count',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      child: DropdownButton<int>(
        value: selectedYear,
        style: const TextStyle(color: AppTheme.textPrimary),
        icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primary),
        underline: const SizedBox(),
        items: availableYears
            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
            .toList(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      child: DropdownButton<int>(
        value: selectedMonth,
        style: const TextStyle(color: AppTheme.textPrimary),
        icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primary),
        underline: const SizedBox(),
        items: monthsList
            .map((m) => DropdownMenuItem<int>(
                  value: m['value'] as int,
                  child: Text(m['name'] as String),
                ))
            .toList(),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('إحصائيات الشهر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _summaryRow('عدد أيام الحضور', '$present', AppTheme.success),
            _summaryRow('عدد أيام الغياب', '$absent', AppTheme.error),
            _summaryRow('عدد مرات التأخير', '$late', AppTheme.warning),
            const Divider(height: 24),
            _summaryRow('إجمالي الأيام المسجلة', '$total', AppTheme.textPrimary),
            _summaryRow('نسبة الحضور', '${rate.toStringAsFixed(1)}%', AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    return monthsList.firstWhere((m) => m['value'] == month)['name'];
  }
}