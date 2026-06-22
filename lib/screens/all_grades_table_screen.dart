import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/parent_service.dart';
import '../theme.dart';

class AllGradesTableScreen extends StatefulWidget {
  final Student child;
  const AllGradesTableScreen({super.key, required this.child});

  @override
  State<AllGradesTableScreen> createState() => _AllGradesTableScreenState();
}

class _AllGradesTableScreenState extends State<AllGradesTableScreen> {
  final ParentService _parentService = ParentService();
  bool isLoading = true;
  bool hasError = false;

  String selectedSemester = 'first';
  String viewMode = 'semester';
  String? selectedMonthKey;
  List<Map<String, dynamic>> availableMonths = [];
  List<Map<String, dynamic>> subjects = [];

  Map<String, Map<String, double>> semMonthlyMarks = {};
  Map<String, double> semExamScores = {};
  Map<String, List<Map<String, dynamic>>> monthActivities = {};
  Map<String, double> monthFinalMarks = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() { isLoading = true; hasError = false; });
    try {
      await _loadSubjects();
      if (subjects.isEmpty) { setState(() => isLoading = false); return; }
      await _loadAvailableMonths();
      if (viewMode == 'semester') {
        await _loadSemesterData();
      } else {
        if (selectedMonthKey != null) await _loadMonthlyData();
      }
      setState(() => isLoading = false);
    } catch (_) {
      setState(() { isLoading = false; hasError = true; });
    }
  }

  Future<void> _loadSubjects() async {
    String? classId = widget.child.classId;
    if (classId == null) {
      final classData = await _parentService.getClassByName(widget.child.level);
      classId = classData?['id'];
    }
    if (classId != null) {
      subjects = await _parentService.getStudentSubjects(classId);
    }
  }

  Future<void> _loadAvailableMonths() async {
    final monthsMap = <String, String>{};
    const monthNames = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    for (final subject in subjects) {
      final exams = await _parentService.getExams(subject['id']);
      for (final e in exams) {
        if (e['semester'] == selectedSemester &&
            e['name'] != 'امتحان الفصل الأول' && e['name'] != 'امتحان الفصل الثاني') {
          final d = DateTime.parse(e['exam_date']);
          final key = '${d.year}-${d.month.toString().padLeft(2,'0')}';
          monthsMap[key] = '${monthNames[d.month-1]} ${d.year}';
        }
      }
    }
    final sorted = monthsMap.entries.toList()..sort((a,b) => a.key.compareTo(b.key));
    availableMonths = sorted.map((e) => {'key': e.key, 'label': e.value}).toList();
    if (selectedMonthKey == null && availableMonths.isNotEmpty) {
      final now = DateTime.now();
      final currentKey = '${now.year}-${now.month.toString().padLeft(2,'0')}';
      selectedMonthKey = availableMonths.any((m) => m['key'] == currentKey) ? currentKey : availableMonths.first['key'];
    }
  }

  Future<void> _loadSemesterData() async {
    semMonthlyMarks.clear();
    semExamScores.clear();
    final examName = selectedSemester == 'first' ? 'امتحان الفصل الأول' : 'امتحان الفصل الثاني';
    for (final subject in subjects) {
      final subjId = subject['id'];
      final monthlyMap = <String, double>{};
      for (final month in availableMonths) {
        final mark = await _parentService.getStudentMonthlyMark(widget.child.id, month['key'], subjId, selectedSemester);
        monthlyMap[month['key']] = mark.toDouble(); // تحويل إلى double
      }
      semMonthlyMarks[subjId] = monthlyMap;
      final examScore = await _getExamScore(subjId, widget.child.id, examName, selectedSemester);
      semExamScores[subjId] = examScore;
    }
  }

  Future<double> _getExamScore(String subjectId, String studentId, String examName, String semester) async {
    final exams = await _parentService.getExams(subjectId);
    final exam = exams.firstWhere(
      (e) => e['name'] == examName && e['semester'] == semester,
      orElse: () => <String, dynamic>{},
    );
    if (exam.isEmpty) return 0;
    final grades = await _parentService.getDetailedGrades(studentId, DateTime.now().year, semester);
    final grade = grades.firstWhere((g) => g['exam_id'] == exam['id'], orElse: () => {'score': 0});
    return (grade['score'] ?? 0).toDouble();
  }

  Future<void> _loadMonthlyData() async {
    if (selectedMonthKey == null) return;
    monthActivities.clear();
    monthFinalMarks.clear();
    final parts = selectedMonthKey!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    for (final subject in subjects) {
      final subjId = subject['id'];
      final allExams = await _parentService.getExams(subjId);
      final monthExams = allExams.where((e) {
        final d = DateTime.parse(e['exam_date']);
        return d.year == year && d.month == month &&
            e['name'] != 'امتحان الفصل الأول' && e['name'] != 'امتحان الفصل الثاني';
      }).toList();
      final grades = await _parentService.getDetailedGrades(widget.child.id, year, selectedSemester);
      double totalScore = 0, totalMax = 0;
      final activities = <Map<String, dynamic>>[];
      for (final exam in monthExams) {
        final grade = grades.firstWhere((g) => g['exam_id'] == exam['id'], orElse: () => {'score': 0});
        final score = (grade['score'] ?? 0).toDouble();
        totalScore += score;
        totalMax += (exam['max_score'] ?? 0).toDouble();
        activities.add({'exam': exam, 'score': score});
      }
      final double monthlyMark = totalMax > 0 ? (totalScore / totalMax) * 20 : 0;
      monthActivities[subjId] = activities;
      monthFinalMarks[subjId] = monthlyMark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('درجات ${widget.child.name}')),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? const Center(child: Text('حدث خطأ'))
                    : subjects.isEmpty
                        ? const Center(child: Text('لا توجد مواد مسجلة'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: viewMode == 'semester'
                                  ? _buildSemesterTable()
                                  : _buildMonthlyTable(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
            ),
            child: DropdownButton<String>(
              value: selectedSemester,
              style: const TextStyle(color: AppTheme.textPrimary),
              icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primary),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'first', child: Text('الفصل الأول')),
                DropdownMenuItem(value: 'second', child: Text('الفصل الثاني')),
              ],
              onChanged: (v) {
                if (v != null) {
                  selectedSemester = v;
                  _initialize();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<String>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppTheme.primary;
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return AppTheme.textSecondary;
              }),
            ),
            segments: const [
              ButtonSegment(value: 'semester', label: Text('فصلي')),
              ButtonSegment(value: 'monthly', label: Text('شهري')),
            ],
            selected: {viewMode},
            onSelectionChanged: (set) {
              viewMode = set.first;
              _initialize();
            },
          ),
          if (viewMode == 'monthly' && availableMonths.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: DropdownButton<String>(
                value: selectedMonthKey,
                style: const TextStyle(color: AppTheme.textPrimary),
                icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primary),
                underline: const SizedBox(),
                items: availableMonths.map((m) => DropdownMenuItem<String>(
                  value: m['key'] as String,
                  child: Text(m['label'] as String),
                )).toList(),
                onChanged: (v) {
                  selectedMonthKey = v;
                  _initialize();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSemesterTable() {
    final months = availableMonths;
    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppTheme.primary.withOpacity(0.1)),
      columns: [
        const DataColumn(label: Text('المادة', style: TextStyle(fontWeight: FontWeight.bold))),
        ...months.map((m) => DataColumn(label: Text(m['label']))),
        const DataColumn(label: Text('الامتحان')),
        const DataColumn(label: Text('المجموع')),
        const DataColumn(label: Text('النسبة')),
        const DataColumn(label: Text('التقدير')),
      ],
      rows: subjects.map((subject) {
        final subjId = subject['id'];
        final monthlyMarks = semMonthlyMarks[subjId] ?? {};
        final examScore = semExamScores[subjId] ?? 0.0;
        double totalMonthly = 0;
        for (final month in months) {
          totalMonthly += (monthlyMarks[month['key']] ?? 0.0);
        }
        final finalTotal = totalMonthly + examScore;
        final maxTotal = months.length * 20 + 60;
        final double percentage = maxTotal > 0 ? (finalTotal / maxTotal) * 100 : 0;
        final grade = _calculateGrade(percentage);

        return DataRow(cells: [
          DataCell(Text(subject['name'] ?? '')),
          ...months.map((m) {
            final mark = monthlyMarks[m['key']] ?? 0.0;
            return DataCell(Center(child: Text(mark.toStringAsFixed(1))));
          }),
          DataCell(Center(child: Text(examScore.toStringAsFixed(1)))),
          DataCell(Center(child: Text('${finalTotal.toStringAsFixed(1)} / $maxTotal'))),
          DataCell(Center(child: Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: percentage >= 60 ? AppTheme.success : AppTheme.error)))),
          DataCell(Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (percentage >= 60 ? AppTheme.success : AppTheme.error).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(grade, style: TextStyle(color: percentage >= 60 ? AppTheme.success : AppTheme.error)),
            ),
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildMonthlyTable() {
    if (selectedMonthKey == null) return const Center(child: Text('اختر شهراً'));
    int maxActivities = monthActivities.values.fold(0, (max, list) => list.length > max ? list.length : max);
    if (maxActivities == 0) return const Center(child: Text('لا توجد أنشطة هذا الشهر'));
    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppTheme.primary.withOpacity(0.1)),
      columns: [
        const DataColumn(label: Text('المادة')),
        ...List.generate(maxActivities, (i) => DataColumn(label: Text('نشاط ${i + 1}'))),
        const DataColumn(label: Text('العلامة (20)')),
      ],
      rows: subjects.map((subject) {
        final subjId = subject['id'];
        final activities = monthActivities[subjId] ?? [];
        final finalMark = monthFinalMarks[subjId] ?? 0.0;
        return DataRow(cells: [
          DataCell(Text(subject['name'] ?? '')),
          ...List.generate(maxActivities, (index) {
            if (index < activities.length) {
              final activity = activities[index];
              return DataCell(Center(child: Text('${activity['score']}')));
            } else {
              return const DataCell(Center(child: Text('')));
            }
          }),
          DataCell(Center(child: Text(finalMark.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))),
        ]);
      }).toList(),
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 80) return 'جيد جداً';
    if (percentage >= 70) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    return 'ضعيف';
  }
}