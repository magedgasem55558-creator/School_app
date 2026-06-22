import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/parent_service.dart';
import '../widgets/gradient_app_bar.dart';

class GradesDetailScreen extends StatefulWidget {
  final Student child;
  final String subjectId;
  final String subjectName;
  const GradesDetailScreen({
    super.key,
    required this.child,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<GradesDetailScreen> createState() => _GradesDetailScreenState();
}

class _GradesDetailScreenState extends State<GradesDetailScreen>
    with TickerProviderStateMixin {
  final ParentService _parentService = ParentService();

  String _viewMode = 'monthly';
  bool _isLoading = false;

  List<Map<String, dynamic>> _availableMonths = [];
  String? _selectedMonthKey;
  List<Map<String, dynamic>> _monthExams = [];
  Map<String, double> _monthScores = {};

  Map<String, dynamic>? _semester1Summary;
  Map<String, dynamic>? _semester2Summary;

  late AnimationController _pulseController;
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _loadAvailableMonths();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMonths() async {
    setState(() => _isLoading = true);
    final exams = await _parentService.getExams(widget.subjectId);
    final monthsMap = <String, String>{};
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    for (final e in exams) {
      final d = DateTime.parse(e['exam_date']);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (e['name'] != 'امتحان الفصل الأول' &&
          e['name'] != 'امتحان الفصل الثاني') {
        monthsMap[key] = '${monthNames[d.month - 1]} ${d.year}';
      }
    }

    final sorted = monthsMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final defaultMonth = sorted.any((e) => e.key == currentKey)
        ? currentKey
        : (sorted.isNotEmpty ? sorted.first.key : null);

    setState(() {
      _availableMonths =
          sorted.map((e) => {'key': e.key, 'label': e.value}).toList();
      _selectedMonthKey = defaultMonth;
      _isLoading = false;
    });

    if (defaultMonth != null) {
      _loadMonthData();
    }
  }

  Future<void> _loadMonthData() async {
    if (_selectedMonthKey == null) return;
    setState(() => _isLoading = true);

    final parts = _selectedMonthKey!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final allExams = await _parentService.getExams(widget.subjectId);
    final monthExams = allExams.where((e) {
      final d = DateTime.parse(e['exam_date']);
      return d.year == year &&
          d.month == month &&
          e['name'] != 'امتحان الفصل الأول' &&
          e['name'] != 'امتحان الفصل الثاني';
    }).toList();

    final grades = await _parentService.getDetailedGrades(
      widget.child.id,
      year,
      'first',
    );

    final scores = <String, double>{};
    for (final exam in monthExams) {
      final grade = grades.firstWhere(
        (g) => g['exam_id'] == exam['id'],
        orElse: () => {'score': 0},
      );
      scores[exam['id']] = (grade['score'] ?? 0).toDouble();
    }

    setState(() {
      _monthExams = monthExams;
      _monthScores = scores;
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>> _buildSemesterSummary(
      String semester, String examName, double examMaxScore) async {
    final allExams = await _parentService.getExams(widget.subjectId);
    final monthSet = <String>{};
    for (final e in allExams) {
      final d = DateTime.parse(e['exam_date']);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (e['semester'] == semester && e['name'] != examName) {
        monthSet.add(key);
      }
    }

    double totalMonthly = 0;
    for (final monthKey in monthSet) {
      totalMonthly += await _parentService.getStudentMonthlyMark(
        widget.child.id,
        monthKey,
        widget.subjectId,
        semester,
      );
    }

    final examResult = await _getExamScore(
        widget.subjectId, widget.child.id, examName, semester, examMaxScore);
    final examScore = examResult['score'];

    final finalTotal = totalMonthly + examScore;
    final maxTotal = (monthSet.length * 20) + examMaxScore;
    final percentage = maxTotal > 0 ? (finalTotal / maxTotal) * 100 : 0.0;
    final grade = _calculateGrade(percentage);
    final status = percentage >= 60 ? 'ناجح' : 'راسب';

    return {
      'monthlyMarks': totalMonthly,
      'examScore': examScore,
      'total': finalTotal,
      'maxTotal': maxTotal,
      'percentage': percentage,
      'grade': grade,
      'status': status,
    };
  }

  Future<Map<String, dynamic>> _getExamScore(String subjectId, String studentId,
      String examName, String semester, double maxScore) async {
    final exams = await _parentService.getExams(subjectId);
    final exam = exams.firstWhere(
      (e) => e['name'] == examName && e['semester'] == semester,
      orElse: () => <String, dynamic>{},
    );
    if (exam.isEmpty) return {'score': 0.0};

    final grades = await _parentService.getDetailedGrades(
      studentId,
      DateTime.now().year,
      semester,
    );
    final grade = grades.firstWhere(
      (g) => g['exam_id'] == exam['id'],
      orElse: () => {'score': 0},
    );
    return {'score': (grade['score'] ?? 0).toDouble()};
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
        title: widget.subjectName,
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
            // خلفية نجوم
            CustomPaint(
              painter: StarFieldPainter(),
              size: Size.infinite,
            ),
            Column(
              children: [
                const SizedBox(height: 12),
                // أزرار الأوضاع
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _modeChip('شهري', 'monthly'),
                      const SizedBox(width: 10),
                      _modeChip('الفصل الأول', 'semester1'),
                      const SizedBox(width: 10),
                      _modeChip('الفصل الثاني', 'semester2'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // اختيار الشهر
                if (_viewMode == 'monthly' && _availableMonths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonthKey,
                          dropdownColor: const Color(0xFF2A0A5C),
                          icon: const Icon(Icons.arrow_drop_down_circle,
                              color: Color(0xFFFFD700)),
                          style:
                              const TextStyle(color: Colors.white, fontSize: 16),
                          isExpanded: true,
                          items: _availableMonths.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['key'],
                              child: Text(m['label']),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() => _selectedMonthKey = v);
                            _loadMonthData();
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD700),
                          ),
                        )
                      : _buildCurrentView(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, String mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _viewMode = mode;
            _isLoading = true;
          });
          if (mode == 'semester1') {
            _semester1Summary = await _buildSemesterSummary(
                'first', 'امتحان الفصل الأول', 60);
          } else if (mode == 'semester2') {
            _semester2Summary = await _buildSemesterSummary(
                'second', 'امتحان الفصل الثاني', 60);
          }
          setState(() => _isLoading = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)])
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05)
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFFFFD700) : Colors.white24,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case 'monthly':
        return _buildMonthlyView();
      case 'semester1':
        return _buildSummaryView('الفصل الأول', _semester1Summary);
      case 'semester2':
        return _buildSummaryView('الفصل الثاني', _semester2Summary);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMonthlyView() {
    if (_selectedMonthKey == null)
      return const Center(child: Text('اختر شهراً'));
    if (_monthExams.isEmpty)
      return const Center(
          child: Text('لا توجد أنشطة هذا الشهر',
              style: TextStyle(color: Colors.white70)));

    double totalScore = 0, totalMax = 0;
    for (final exam in _monthExams) {
      totalScore += _monthScores[exam['id']] ?? 0;
      totalMax += (exam['max_score'] ?? 0).toDouble();
    }
    final monthlyMark = totalMax > 0 ? (totalScore / totalMax) * 20 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // عنوان الشهر بتأثير ذهبي
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.02),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      Colors.white,
                      const Color(0xFFFFA000),
                    ],
                    stops: [
                      0.0,
                      0.5 + _pulseController.value * 0.3,
                      1.0,
                    ],
                    transform: GradientRotation(math.pi / 6),
                  ).createShader(bounds),
                  child: Text(
                    'أنشطة شهر ${_availableMonths.firstWhere((m) => m['key'] == _selectedMonthKey, orElse: () => {'label': ''})['label']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // جدول الدرجات الزجاجي
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Table(
              border:
                  TableBorder.all(color: Colors.white.withOpacity(0.1)),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.3),
                        const Color(0xFFFFA000).withOpacity(0.1),
                      ],
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text('النشاط',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text('الدرجة',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text('الأقصى',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                  ],
                ),
                ..._monthExams.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final exam = entry.value;
                  final score = _monthScores[exam['id']] ?? 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: idx % 2 == 0
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(exam['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(score.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFFFD700))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(exam['max_score'].toString(),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 15)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // العلامة الشهرية مع توهج كوني
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700)
                          .withOpacity(0.5 + _pulseController.value * 0.3),
                      blurRadius: 25 + _pulseController.value * 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'العلامة الشهرية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${monthlyMark.toStringAsFixed(1)} / 20',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(String title, Map<String, dynamic>? summary) {
    if (summary == null)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    final percentage = summary['percentage'] as double;
    final grade = summary['grade'] as String;
    final status = summary['status'] as String;
    final isPassed = status == 'ناجح';
    final statusColor = isPassed ? const Color(0xFF00E676) : const Color(0xFFFF1744);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // عنوان الفصل
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Colors.white, Color(0xFFFFA000)],
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // حلقة النسبة المئوية
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage / 100),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: isPassed ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        grade,
                        style: TextStyle(
                          fontSize: 18,
                          color: isPassed ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // بطاقة الحالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // تفاصيل الدرجات
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _detailRow('مجموع الأعمال الشهرية',
                    summary['monthlyMarks'].toStringAsFixed(1)),
                _detailRow('الامتحان',
                    summary['examScore'].toStringAsFixed(1)),
                const Divider(
                    color: Color(0xFFFFD700), height: 30),
                _detailRow('المجموع',
                    '${summary['total'].toStringAsFixed(1)} / ${summary['maxTotal']}'),
                _detailRow('النسبة',
                    '${summary['percentage'].toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFFFFD700))),
        ],
      ),
    );
  }
}

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}