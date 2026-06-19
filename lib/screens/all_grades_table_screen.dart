import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/parent_service.dart';
import '../widgets/gradient_app_bar.dart';

class AllGradesTableScreen extends StatefulWidget {
  final Student child;
  const AllGradesTableScreen({super.key, required this.child});

  @override
  State<AllGradesTableScreen> createState() => _AllGradesTableScreenState();
}

class _AllGradesTableScreenState extends State<AllGradesTableScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      await _loadSubjects();
      if (subjects.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      await _loadAvailableMonths();
      if (viewMode == 'semester') {
        await _loadSemesterData();
      } else {
        if (selectedMonthKey != null) await _loadMonthlyData();
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
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
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    for (final subject in subjects) {
      final exams = await _parentService.getExams(subject['id']);
      for (final e in exams) {
        if (e['semester'] == selectedSemester &&
            e['name'] != 'امتحان الفصل الأول' &&
            e['name'] != 'امتحان الفصل الثاني') {
          final d = DateTime.parse(e['exam_date']);
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
          monthsMap[key] = '${monthNames[d.month - 1]} ${d.year}';
        }
      }
    }
    final sorted = monthsMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    availableMonths = sorted.map((e) => {'key': e.key, 'label': e.value}).toList();
    if (selectedMonthKey == null && availableMonths.isNotEmpty) {
      final now = DateTime.now();
      final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      selectedMonthKey = availableMonths.any((m) => m['key'] == currentKey)
          ? currentKey
          : availableMonths.first['key'];
    }
  }

  Future<void> _loadSemesterData() async {
    semMonthlyMarks.clear();
    semExamScores.clear();
    final examName = selectedSemester == 'first' ? 'امتحان الفصل الأول' : 'امتحان الفصل الثاني';
    const examMaxScore = 60.0;

    for (final subject in subjects) {
      final subjId = subject['id'];
      final monthlyMap = <String, double>{};
      for (final month in availableMonths) {
        final mark = await _parentService.getStudentMonthlyMark(
          widget.child.id, month['key'], subjId, selectedSemester,
        );
        monthlyMap[month['key']] = mark;
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
    if (exam.isEmpty) return 0.0;
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
            e['name'] != 'امتحان الفصل الأول' &&
            e['name'] != 'امتحان الفصل الثاني';
      }).toList();

      final grades = await _parentService.getDetailedGrades(widget.child.id, year, selectedSemester);
      double totalScore = 0, totalMax = 0;
      final activities = <Map<String, dynamic>>[];
      for (final exam in monthExams) {
        final grade = grades.firstWhere(
          (g) => g['exam_id'] == exam['id'],
          orElse: () => {'score': 0},
        );
        final score = (grade['score'] ?? 0).toDouble();
        totalScore += score;
        totalMax += (exam['max_score'] ?? 0).toDouble();
        activities.add({
          'exam': exam,
          'score': score,
        });
      }
      final monthlyMark = totalMax > 0 ? (totalScore / totalMax) * 20 : 0.0;
      monthActivities[subjId] = activities;
      monthFinalMarks[subjId] = monthlyMark;
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 80) return 'جيد جداً';
    if (percentage >= 70) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    return 'ضعيف';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'درجات ${widget.child.name}',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0221),
              Color(0xFF2A0A5C),
              Color(0xFF4A148C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: StarFieldPainter(),
              size: Size.infinite,
            ),
            Column(
              children: [
                _buildFilters(),
                const Divider(color: Color(0xFFFFD700), height: 1),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD700),
                          ),
                        )
                      : hasError
                          ? const Center(
                              child: Text(
                                'حدث خطأ أثناء تحميل البيانات',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : subjects.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد مواد مسجلة',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
            ),
            child: DropdownButton<String>(
              value: selectedSemester,
              dropdownColor: const Color(0xFF2A0A5C),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFFFD700)),
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
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFFD700);
                  }
                  return Colors.white.withOpacity(0.1);
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;
                  }
                  return Colors.white70;
                },
              ),
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
              ),
              child: DropdownButton<String>(
                value: selectedMonthKey,
                dropdownColor: const Color(0xFF2A0A5C),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFFFD700)),
                underline: const SizedBox(),
                items: availableMonths.map((m) {
                  return DropdownMenuItem<String>(
                    value: m['key'] as String,
                    child: Text(m['label'] as String),
                  );
                }).toList(),
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
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFFFFD700).withOpacity(0.2),
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          return Colors.white.withOpacity(0.05);
        },
      ),
      columnSpacing: 20,
      columns: [
        _buildColumnHeader('المادة'),
        ...months.map((m) => _buildColumnHeader(m['label'])),
        _buildColumnHeader('الامتحان'),
        _buildColumnHeader('المجموع'),
        _buildColumnHeader('النسبة'),
        _buildColumnHeader('التقدير'),
      ],
      rows: subjects.map((subject) {
        final subjId = subject['id'];
        final monthlyMarks = semMonthlyMarks[subjId] ?? {};
        final examScore = semExamScores[subjId] ?? 0.0;
        double totalMonthly = 0;
        for (final month in months) {
          totalMonthly += monthlyMarks[month['key']] ?? 0.0;
        }
        final finalTotal = totalMonthly + examScore;
        final maxTotal = months.length * 20 + 60;
        final percentage = maxTotal > 0 ? (finalTotal / maxTotal) * 100 : 0.0;
        final grade = _calculateGrade(percentage);

        return DataRow(cells: [
          DataCell(Text(subject['name'] ?? '',
              style: const TextStyle(color: Colors.white))),
          ...months.map((m) {
            final mark = monthlyMarks[m['key']] ?? 0.0;
            return DataCell(Center(
              child: Text(mark.toStringAsFixed(1),
                  style: const TextStyle(color: Color(0xFFFFD700))),
            ));
          }),
          DataCell(Center(
            child: Text(examScore.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70)),
          )),
          DataCell(Center(
            child: Text('${finalTotal.toStringAsFixed(1)} / $maxTotal',
                style: const TextStyle(color: Colors.white)),
          )),
          DataCell(Center(
            child: Text('${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: percentage >= 60 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                )),
          )),
          DataCell(Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: percentage >= 60 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(grade,
                  style: TextStyle(
                    color: percentage >= 60 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          )),
        ]);
      }).toList(),
    );
  }

  // تم التعديل هنا: تغيير نوع الإرجاع إلى DataColumn
  DataColumn _buildColumnHeader(String text) {
    return DataColumn(
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMonthlyTable() {
    if (selectedMonthKey == null)
      return const Center(
          child: Text('اختر شهراً', style: TextStyle(color: Colors.white70)));
    int maxActivities = 0;
    for (final list in monthActivities.values) {
      if (list.length > maxActivities) maxActivities = list.length;
    }
    if (maxActivities == 0)
      return const Center(
          child: Text('لا توجد أنشطة هذا الشهر',
              style: TextStyle(color: Colors.white70)));

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFFFFD700).withOpacity(0.2),
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color>(
        (states) => Colors.white.withOpacity(0.05),
      ),
      columnSpacing: 20,
      columns: [
        _buildColumnHeader('المادة'),
        ...List.generate(maxActivities,
            (i) => _buildColumnHeader('نشاط ${i + 1}')),
        _buildColumnHeader('العلامة (20)'),
      ],
      rows: subjects.map((subject) {
        final subjId = subject['id'];
        final activities = monthActivities[subjId] ?? [];
        final finalMark = monthFinalMarks[subjId] ?? 0.0;

        return DataRow(cells: [
          DataCell(Text(subject['name'] ?? '',
              style: const TextStyle(color: Colors.white))),
          ...List.generate(maxActivities, (index) {
            if (index < activities.length) {
              final activity = activities[index];
              final examName = activity['exam']['name'] ?? '';
              final score = activity['score'].toStringAsFixed(1);
              return DataCell(Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(examName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(score,
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ));
            } else {
              return const DataCell(Center(child: Text('')));
            }
          }),
          DataCell(Center(
            child: Text(finalMark.toStringAsFixed(1),
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          )),
        ]);
      }).toList(),
    );
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
      final radius = random.nextDouble() * 2.4;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}