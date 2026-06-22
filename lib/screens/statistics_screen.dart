import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/parent_service.dart';
import '../theme.dart';

class StatisticsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? classId;
  final String? level;
  const StatisticsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.classId,
    this.level,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ParentService _parentService = ParentService();
  bool isLoading = true;
  String? errorMessage;

  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];
  List<String> availableMonths = [];
  String? selectedMonth1;
  String? selectedMonth2;

  Map<String, Map<int, double>> monthlyDayStatus = {};
  Map<String, double> monthlyRate = {};
  String comparisonTrendMessage = '';

  List<Map<String, dynamic>> semesterComparison = [];
  double overallChangePercent = 0.0;
  String overallTrendMsg = '';

  @override
  void initState() {
    super.initState();
    for (int y = selectedYear - 2; y <= selectedYear; y++) {
      availableYears.add(y);
    }
    _generateAvailableMonths();
    _loadAllData();
  }

  void _generateAvailableMonths() {
    List<String> months = [];
    for (int m = 1; m <= 12; m++) {
      months.add('$selectedYear-${m.toString().padLeft(2, '0')}');
    }
    availableMonths = months;
    final now = DateTime.now();
    selectedMonth1 = '$selectedYear-${now.month.toString().padLeft(2, '0')}';
    int prevMonth = now.month - 1;
    if (prevMonth < 1) prevMonth = 12;
    selectedMonth2 = '$selectedYear-${prevMonth.toString().padLeft(2, '0')}';
    if (selectedMonth1 == selectedMonth2) {
      prevMonth = now.month - 2;
      if (prevMonth < 1) prevMonth = 12;
      selectedMonth2 = '$selectedYear-${prevMonth.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await Future.wait([_loadAttendanceComparison(), _loadComparisonData()]);
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadAttendanceComparison() async {
    if (selectedMonth1 == null || selectedMonth2 == null) return;
    monthlyDayStatus.clear();
    monthlyRate.clear();

    for (String monthKey in [selectedMonth1!, selectedMonth2!]) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final start = DateFormat('yyyy-MM-dd').format(DateTime(year, month, 1));
      final end = DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));

      List<Map<String, dynamic>> records;
      try {
        records = await _parentService.getAttendance(widget.studentId, start, end);
      } catch (_) {
        records = [];
      }

      int daysInMonth = DateTime(year, month + 1, 0).day;
      Map<int, double> dayValues = {};
      Map<String, String> dayStatusMap = {};
      for (var r in records) {
        String day = r['date'].toString().substring(8, 10);
        dayStatusMap[day] = r['status'];
      }
      for (int d = 1; d <= daysInMonth; d++) {
        String dayStr = d.toString().padLeft(2, '0');
        String status = dayStatusMap[dayStr] ?? 'غير مسجل';
        double value;
        switch (status) {
          case 'present':
            value = 100;
            break;
          case 'absent':
            value = 0;
            break;
          case 'late':
            value = 50;
            break;
          default:
            value = -1;
        }
        dayValues[d] = value;
      }
      monthlyDayStatus[monthKey] = dayValues;

      int presentCount = records.where((r) => r['status'] == 'present').length;
      double rate = daysInMonth > 0 ? (presentCount / daysInMonth) * 100 : 0.0;
      monthlyRate[monthKey] = rate;
    }

    double rate1 = monthlyRate[selectedMonth1] ?? 0;
    double rate2 = monthlyRate[selectedMonth2] ?? 0;
    if (rate1 > rate2) {
      comparisonTrendMessage = '📈 الشهر ${DateFormat('MMMM', 'ar').format(DateTime.parse('${selectedMonth1!}-01'))} أفضل من ${DateFormat('MMMM', 'ar').format(DateTime.parse('${selectedMonth2!}-01'))}';
    } else if (rate1 < rate2) {
      comparisonTrendMessage = '📉 الشهر ${DateFormat('MMMM', 'ar').format(DateTime.parse('${selectedMonth1!}-01'))} أقل من ${DateFormat('MMMM', 'ar').format(DateTime.parse('${selectedMonth2!}-01'))}';
    } else {
      comparisonTrendMessage = '➡️ الشهران متساويان';
    }
  }

  Future<void> _loadComparisonData() async {
    String? classId = widget.classId;
    if (classId == null && widget.level != null) {
      try {
        final classData = await _parentService.getClassByName(widget.level!);
        classId = classData?['id'];
      } catch (_) {}
    }
    if (classId == null) {
      semesterComparison = [];
      return;
    }

    final subjects = await _parentService.getSubjectsByClass(classId);
    List<Map<String, dynamic>> grades1, grades2;
    try {
      grades1 = await _parentService.getDetailedGrades(widget.studentId, selectedYear, 'first');
      grades2 = await _parentService.getDetailedGrades(widget.studentId, selectedYear, 'second');
    } catch (_) {
      grades1 = [];
      grades2 = [];
    }

    double totalChange = 0;
    int subjectCount = 0;
    final List<Map<String, dynamic>> list = [];

    for (final subject in subjects) {
      final subjId = subject['id'];
      final subGrades1 = grades1.where((g) => g['subject_id'] == subjId).toList();
      final subGrades2 = grades2.where((g) => g['subject_id'] == subjId).toList();

      double percentage1 = _calculatePercentage(subGrades1);
      double percentage2 = _calculatePercentage(subGrades2);
      if (subGrades1.isEmpty && subGrades2.isEmpty) continue;

      double change = percentage2 - percentage1;
      String trend = change > 0 ? '📈' : (change < 0 ? '📉' : '➡️');
      Color trendColor = change > 0
          ? AppTheme.success
          : (change < 0 ? AppTheme.error : AppTheme.textSecondary);

      list.add({
        'subjectName': subject['name'],
        'percentage1': percentage1,
        'percentage2': percentage2,
        'change': change,
        'trend': trend,
        'trendColor': trendColor,
      });
      totalChange += change;
      subjectCount++;
    }

    overallChangePercent = subjectCount > 0 ? totalChange / subjectCount : 0.0;
    overallTrendMsg = overallChangePercent > 0
        ? '📈 تحسن عام في الدرجات'
        : (overallChangePercent < 0 ? '📉 تراجع عام في الدرجات' : '➡️ استقرار عام');
    semesterComparison = list;
  }

  double _calculatePercentage(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0.0;
    double totalScore = 0, totalMax = 0;
    for (final g in grades) {
      totalScore += (g['score'] ?? 0).toDouble();
      totalMax += (g['max_score'] ?? 0).toDouble();
    }
    return totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إحصائيات ${widget.studentName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildYearSelector(),
                      const SizedBox(height: 20),
                      _sectionTitle('مقارنة الحضور بين شهرين'),
                      const SizedBox(height: 12),
                      _buildMonthSelectors(),
                      const SizedBox(height: 16),
                      _buildAttendanceComparisonChart(),
                      const SizedBox(height: 8),
                      _buildTrendCard(comparisonTrendMessage),
                      const SizedBox(height: 30),
                      _sectionTitle('مقارنة الدرجات بين الفصلين'),
                      const SizedBox(height: 16),
                      if (semesterComparison.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا توجد درجات للمقارنة'),
                        )
                      else ...[
                        _buildComparisonChart(),
                        const SizedBox(height: 24),
                        _buildOverallComparisonCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary),
      );

  Widget _buildYearSelector() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          ),
          child: DropdownButton<int>(
            value: selectedYear,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
            icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primary),
            underline: const SizedBox(),
            items: availableYears
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                selectedYear = val;
                _generateAvailableMonths();
                _loadAllData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelectors() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMonthDropdown(selectedMonth1, (v) { if (v != null) { selectedMonth1 = v; _loadAttendanceComparison(); } }),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('مقابل', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        _buildMonthDropdown(selectedMonth2, (v) { if (v != null) { selectedMonth2 = v; _loadAttendanceComparison(); } }),
      ],
    );
  }

  Widget _buildMonthDropdown(String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        style: const TextStyle(color: AppTheme.textPrimary),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
        underline: const SizedBox(),
        items: availableMonths.map((m) {
          String label = DateFormat('MMMM', 'ar').format(DateTime.parse('$m-01'));
          return DropdownMenuItem(value: m, child: Text(label));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAttendanceComparisonChart() {
    if (selectedMonth1 == null || selectedMonth2 == null) return const SizedBox.shrink();
    final days1 = monthlyDayStatus[selectedMonth1] ?? {};
    final days2 = monthlyDayStatus[selectedMonth2] ?? {};
    if (days1.isEmpty && days2.isEmpty) {
      return const Text('لا توجد بيانات حضور لهذين الشهرين',
          style: TextStyle(color: AppTheme.textSecondary));
    }
    int maxDays = math.max(days1.length, days2.length);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: 100,
              barGroups: List.generate(maxDays, (index) {
                int day = index + 1;
                double val1 = days1[day] ?? -1;
                double val2 = days2[day] ?? -1;
                return BarChartGroupData(
                  x: day,
                  barRods: [
                    if (val1 >= 0)
                      BarChartRodData(
                        toY: val1,
                        color: AppTheme.primary.withOpacity(0.7),
                        width: 6,
                      ),
                    if (val2 >= 0)
                      BarChartRodData(
                        toY: val2,
                        color: AppTheme.warning.withOpacity(0.7),
                        width: 6,
                      ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 25,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 5 == 0 || value == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${value.toInt()}',
                              style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: 100,
              barGroups: semesterComparison.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: item['percentage1'],
                      color: AppTheme.primary.withOpacity(0.7),
                      width: 14,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: item['percentage2'],
                      color: AppTheme.warning.withOpacity(0.7),
                      width: 14,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 20,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < semesterComparison.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            semesterComparison[idx]['subjectName'],
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              overallTrendMsg,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '${overallChangePercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}