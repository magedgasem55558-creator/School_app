import 'package:flutter/material.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن المدرسة النموذجية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم الهيرو – بتصميم هادئ وراقي
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 56,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'عن المدرسة النموذجية',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مسيرة عطاء منذ عام 1990',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // وصف المدرسة
                  Text(
                    'تأسست المدرسة عام 1990 بهدف تقديم تعليم متميز يجمع بين الأصالة والمعاصرة.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نحرص على تنمية مهارات الطلاب العلمية والثقافية والرياضية، ونؤمن بأن كل طالب لديه موهبة تستحق الرعاية.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  // الرؤية والرسالة والقيم
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMissionCard(
                        context,
                        icon: Icons.visibility,
                        title: 'رؤيتنا',
                        desc: 'قيادة التغيير في مجال التعليم نحو مجتمع معرفي مبتكر.',
                      ),
                      _buildMissionCard(
                        context,
                        icon: Icons.message,
                        title: 'رسالتنا',
                        desc: 'إعداد جيل واعٍ قادر على مواجهة تحديات المستقبل بأخلاق عالية وعلم نافع.',
                      ),
                      _buildMissionCard(
                        context,
                        icon: Icons.star,
                        title: 'قيمنا',
                        desc: 'الإتقان، الإبداع، الاحترام، الانتماء، والمسؤولية المجتمعية.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // إحصائيات فخرية
                  Text(
                    'إحصائيات فخرية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard(context, '+30', 'عاماً من التميز'),
                      _buildStatCard(context, '+5,000', 'خريج'),
                      _buildStatCard(context, '98%', 'نسبة نجاح'),
                      _buildStatCard(context, '+150', 'معلم ومعلمة'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // اقتباس
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '“نحن لا نعلّم فقط، بل نصنع أجيالاً تفتخر بها الأمة”',
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        height: 1.6,
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

  Widget _buildMissionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    height: 1.5,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
