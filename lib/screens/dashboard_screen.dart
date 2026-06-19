import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/parent_service.dart';
import '../models/student.dart';
import '../widgets/gradient_app_bar.dart';
import 'all_grades_table_screen.dart';
import 'attendance_screen.dart';
import 'statistics_screen.dart';
import 'about_screen.dart';
import 'bus_tracking_screen.dart'; // <-- استيراد شاشة تتبع الباص

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final ParentService _parentService = ParentService();

  List<Student> children = [];
  Student? selectedChild;
  int selectedIndex = 0;

  late AnimationController _pulseController;
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    children = _auth.children;
    if (children.isNotEmpty) selectChild(0);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void selectChild(int index) {
    setState(() {
      selectedIndex = index;
      selectedChild = children[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'لوحة تحكم ولي الأمر',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              _auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
            if (children.isEmpty)
              const Center(
                child: Text('لا يوجد أبناء', style: TextStyle(fontSize: 18, color: Colors.white70)),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 16),
                  // شريط اختيار الأبناء بتصميم كوني
                  SizedBox(
                    height: 55,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: children.length,
                      itemBuilder: (context, i) {
                        final child = children[i];
                        final isSelected = i == selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () => selectChild(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white24,
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withOpacity(0.5),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  child.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // بطاقات التحكم
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.1,
                      children: [
                        _buildLuxuryCard(
                          icon: Icons.grade_rounded,
                          title: 'الدرجات',
                          color: const Color(0xFF7C4DFF),
                          glowColor: const Color(0xFFB388FF),
                          onTap: () {
                            if (selectedChild != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllGradesTableScreen(child: selectedChild!),
                                ),
                              );
                            }
                          },
                        ),
                        _buildLuxuryCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'الحضور',
                          color: const Color(0xFF00BFA5),
                          glowColor: const Color(0xFF64FFDA),
                          onTap: () {
                            if (selectedChild != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceScreen(studentId: selectedChild!.id),
                                ),
                              );
                            }
                          },
                        ),
                        _buildLuxuryCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'الماليات',
                          color: const Color(0xFFFF9100),
                          glowColor: const Color(0xFFFFD180),
                          onTap: () {
                            if (selectedChild != null) {
                              _showFinancialDialog(context);
                            }
                          },
                        ),
                        _buildLuxuryCard(
                          icon: Icons.insert_chart_outlined_rounded,
                          title: 'الإحصائيات',
                          color: const Color(0xFFE91E63),
                          glowColor: const Color(0xFFFF80AB),
                          onTap: () {
                            if (selectedChild != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StatisticsScreen(
                                    studentId: selectedChild!.id,
                                    studentName: selectedChild!.name,
                                    classId: selectedChild!.classId,
                                    level: selectedChild!.level,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        // ✨ بطاقة تتبع الباص (جديد)
                        _buildLuxuryCard(
                          icon: Icons.directions_bus_rounded,
                          title: 'تتبع الباص',
                          color: const Color(0xFF26C6DA),
                          glowColor: const Color(0xFF80DEEA),
                          onTap: () {
                            if (selectedChild != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BusTrackingScreen(
                                    studentId: selectedChild!.id,
                                    studentName: selectedChild!.name,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onTap,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.25 + _pulseController.value * 0.15),
                            blurRadius: 25 + _pulseController.value * 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(0.5),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 44, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFinancialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0536), Color(0xFF2A0A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 50, color: Color(0xFFFFD700)),
              const SizedBox(height: 16),
              const Text('الماليات',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchFinancialData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                  }
                  final data = snapshot.data ?? {};
                  return Column(
                    children: [
                      _financialRow('الرسوم الدراسية', data['school_fees'] ?? 0),
                      _financialRow('الزي المدرسي', data['uniform_fees'] ?? 0),
                      _financialRow('الباص', data['bus_fees'] ?? 0),
                      const Divider(color: Color(0xFFFFD700), height: 24),
                      _financialRow('الإجمالي', data['total_amount'] ?? 0, bold: true),
                      _financialRow('المدفوع', data['paid_amount'] ?? 0, color: const Color(0xFF00E676)),
                      _financialRow('المتبقي', (data['total_amount'] ?? 0) - (data['paid_amount'] ?? 0), color: const Color(0xFFFF1744)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('موافق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchFinancialData() async {
    if (selectedChild == null) return {};
    String? classId = selectedChild!.classId;
    if (classId == null) {
      final classData = await _parentService.getClassByName(selectedChild!.level);
      classId = classData?['id'];
    }
    final classData = classId != null ? await _parentService.getClassDataSafe(classId) : {};
    return {
      'school_fees': classData['school_fees'] ?? 0,
      'uniform_fees': classData['uniform_fees'] ?? 0,
      'bus_fees': classData['bus_fees'] ?? 0,
      'total_amount': (classData['school_fees'] ?? 0) + (classData['uniform_fees'] ?? 0) + (classData['bus_fees'] ?? 0),
      'paid_amount': selectedChild!.paidAmount ?? 0,
    };
  }

  Widget _financialRow(String label, dynamic value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 17,
                  color: Colors.white70)),
          Text('${value ?? 0} ريال',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.white,
                  fontSize: 17)),
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
      final radius = random.nextDouble() * 2.2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.7 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}