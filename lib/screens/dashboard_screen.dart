import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/parent_service.dart';
import '../theme.dart';
import 'all_grades_table_screen.dart';
import 'attendance_screen.dart';
import 'statistics_screen.dart';
import 'bus_tracking_screen.dart';
import 'about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  final ParentService _parentService = ParentService();

  List<Student> children = [];
  Student? selectedChild;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    children = _auth.children;
    if (children.isNotEmpty) selectChild(0);
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
      appBar: AppBar(
        title: const Text('لوحة تحكم ولي الأمر'),
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
      body: children.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد أبناء',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      final isSelected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(child.name),
                          selected: isSelected,
                          onSelected: (_) => selectChild(index),
                          selectedColor: AppTheme.primary.withOpacity(0.15),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildCard(
                        icon: Icons.grade_rounded,
                        title: 'الدرجات',
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
                      _buildCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'الحضور',
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
                      _buildCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'الماليات',
                        onTap: () {
                          if (selectedChild != null) _showFinancialDialog(context);
                        },
                      ),
                      _buildCard(
                        icon: Icons.insert_chart_outlined_rounded,
                        title: 'الإحصائيات',
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
                      _buildCard(
                        icon: Icons.directions_bus_rounded,
                        title: 'تتبع الباص',
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
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinancialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('الماليات',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchFinancialData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? {};
                  return Column(
                    children: [
                      _financialRow('الرسوم الدراسية', data['school_fees'] ?? 0),
                      _financialRow('الزي المدرسي', data['uniform_fees'] ?? 0),
                      _financialRow('الباص', data['bus_fees'] ?? 0),
                      const Divider(height: 24),
                      _financialRow('الإجمالي', data['total_amount'] ?? 0,
                          bold: true),
                      _financialRow('المدفوع', data['paid_amount'] ?? 0,
                          color: AppTheme.success),
                      _financialRow(
                          'المتبقي',
                          (data['total_amount'] ?? 0) -
                              (data['paid_amount'] ?? 0),
                          color: AppTheme.error),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('موافق'),
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
      final classData =
          await _parentService.getClassByName(selectedChild!.level);
      classId = classData?['id'];
    }
    final classData =
        classId != null ? await _parentService.getClassDataSafe(classId) : {};
    final schoolFees = classData['school_fees'] ?? 0;
    final uniformFees = classData['uniform_fees'] ?? 0;
    final busFees = classData['bus_fees'] ?? 0;
    return {
      'school_fees': schoolFees,
      'uniform_fees': uniformFees,
      'bus_fees': busFees,
      'total_amount': schoolFees + uniformFees + busFees,
      'paid_amount': selectedChild!.paidAmount ?? 0,
    };
  }

  Widget _financialRow(String label, dynamic value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: AppTheme.textSecondary)),
          Text('${value ?? 0} ريال',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}