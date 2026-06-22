import 'package:flutter/material.dart';
import '../theme.dart';

class CurriculumScreen extends StatelessWidget {
  const CurriculumScreen({super.key});

  final List<Map<String, dynamic>> grades = const [
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنهج اليمني')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: grades.length,
        itemBuilder: (context, index) {
          final grade = grades[index];
          return _buildGradeCard(context, grade['grade'], grade['subjects']);
        },
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, String grade, List<String> subjects) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grade,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: subjects.map((subject) {
                return Chip(
                  label: Text(subject),
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppTheme.primary),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}