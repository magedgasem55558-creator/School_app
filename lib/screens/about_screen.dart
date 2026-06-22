import 'package:flutter/material.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('عن المدرسة النموذجية'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم الهيرو
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.school, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'عن المدرسة النموذجية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مسيرة عطاء منذ عام 1990',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // وصف المدرسة
                  Text(
                    'تأسست المدرسة عام 1990 بهدف تقديم تعليم متميز يجمع بين الأصالة والمعاصرة.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'نحرص على تنمية مهارات الطلاب العلمية والثقافية والرياضية، ونؤمن بأن كل طالب لديه موهبة تستحق الرعاية.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // الرؤية والرسالة والقيم – متكيف مع الشاشات الصغيرة
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // نجعل البطاقات 3 أعمدة فقط إذا كان العرض أكبر من 360
                      final crossAxisCount = constraints.maxWidth > 360 ? 3 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildMissionCard(context,
                              icon: Icons.visibility,
                              title: 'رؤيتنا',
                              desc: 'قيادة التغيير في مجال التعليم نحو مجتمع معرفي مبتكر.'),
                          _buildMissionCard(context,
                              icon: Icons.message,
                              title: 'رسالتنا',
                              desc: 'إعداد جيل واعٍ قادر على مواجهة تحديات المستقبل.'),
                          _buildMissionCard(context,
                              icon: Icons.star,
                              title: 'قيمنا',
                              desc: 'الإتقان، الإبداع، الاحترام، الانتماء، والمسؤولية المجتمعية.'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  // إحصائيات فخرية
                  Text(
                    'إحصائيات فخرية',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard(context, '+30', 'عاماً من التميز'),
                      _buildStatCard(context, '+5,000', 'خريج'),
                      _buildStatCard(context, '98%', 'نسبة نجاح'),
                      _buildStatCard(context, '+150', 'معلم ومعلمة'),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // اقتباس
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '“نحن لا نعلّم فقط، بل نصنع أجيالاً تفتخر بها الأمة”',
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context,
      {required IconData icon, required String title, required String desc}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppTheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String number, String label) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}