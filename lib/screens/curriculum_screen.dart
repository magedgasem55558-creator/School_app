import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/gradient_app_bar.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  final List<Map<String, dynamic>> grades = [
    {'grade': 'الصف الأول الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية']},
    {'grade': 'الصف الثاني الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية']},
    {'grade': 'الصف الثالث الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية']},
    {'grade': 'الصف الرابع الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات']},
    {'grade': 'الصف الخامس الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات']},
    {'grade': 'الصف السادس الابتدائي', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات']},
    {'grade': 'الصف السابع', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات', 'فيزياء', 'كيمياء']},
    {'grade': 'الصف الثامن', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات', 'فيزياء', 'كيمياء']},
    {'grade': 'الصف التاسع', 'subjects': ['قرآن كريم', 'لغة عربية', 'رياضيات', 'علوم', 'تربية إسلامية', 'لغة إنجليزية', 'اجتماعيات', 'فيزياء', 'كيمياء']},
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'المنهج اليمني'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0221), Color(0xFF2A0A5C), Color(0xFF6A1B9A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: StarFieldPainter(), // الآن سيتم التعرف عليه
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 40 * (1 - value)),
                      child: _buildGradeCard(grades[index]['grade'], grades[index]['subjects']),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGradeCard(String grade, List<String> subjects) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    Colors.white,
                    const Color(0xFFFFD700),
                  ],
                  stops: [
                    0.0,
                    _shimmerController.value * 2 % 1,
                    1.0,
                  ],
                  transform: GradientRotation(math.pi / 4),
                ).createShader(bounds),
                child: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: subjects.map((subject) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.3),
                      const Color(0xFFFFA000).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFFFD700)),
                    const SizedBox(width: 6),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// تعريف StarFieldPainter داخل نفس الملف
class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.5;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.7 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}