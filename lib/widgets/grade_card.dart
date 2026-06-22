import 'package:flutter/material.dart';

class GradeCard extends StatefulWidget {
  final String subjectName;
  final double monthlyMark;
  final double examScore;
  final double total;
  final double maxTotal;
  final double percentage;
  final String grade;
  final String status;
  final VoidCallback? onTap;

  const GradeCard({
    super.key,
    required this.subjectName,
    required this.monthlyMark,
    required this.examScore,
    required this.total,
    required this.maxTotal,
    required this.percentage,
    required this.grade,
    required this.status,
    this.onTap,
  });

  @override
  State<GradeCard> createState() => _GradeCardState();
}

class _GradeCardState extends State<GradeCard> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'ممتاز': return const Color(0xFF4CAF50);
      case 'جيد جداً': return const Color(0xFF2196F3);
      case 'جيد': return const Color(0xFFFF9800);
      case 'مقبول': return const Color(0xFFFFC107);
      case 'ضعيف': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.status == 'ناجح';
    final statusColor = isPassed ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final gradeColor = _gradeColor(widget.grade);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              shadowColor: gradeColor.withOpacity(0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        gradeColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.subjectName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildMark('أعمال شهرية', widget.monthlyMark),
                          const SizedBox(width: 20),
                          _buildMark('الامتحان', widget.examScore),
                          const SizedBox(width: 20),
                          _buildMark('المجموع', widget.total, suffix: '/${widget.maxTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // شريط التقدم المتحرك
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _progressAnimation.value,
                                  backgroundColor: Colors.grey[200],
                                  color: gradeColor,
                                  minHeight: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'النسبة: ${(widget.percentage).toStringAsFixed(1)}%',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: gradeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.grade,
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMark(String label, double value, {String suffix = ''}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(1)}$suffix',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}