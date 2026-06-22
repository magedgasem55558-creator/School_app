import 'package:flutter/material.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'المدرسة النموذجية',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'مرحباً بكم في منصة التعليم المتميز',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'مسيرة عطاء منذ عام 1990',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 48),
                _buildCard(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'المنهج اليمني',
                  subtitle: 'تصفح المناهج الدراسية الرسمية',
                  onTap: () => Navigator.pushNamed(context, '/curriculum'),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  icon: Icons.login_rounded,
                  title: 'دخول ولي الأمر',
                  subtitle: 'متابعة الأبناء والدرجات والحضور',
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'عن المدرسة',
                  subtitle: 'تعرف على رؤيتنا ورسالتنا',
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: AppTheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}