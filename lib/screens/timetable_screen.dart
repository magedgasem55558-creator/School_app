import 'package:flutter/material.dart';
import '../services/timetable_service.dart';
import '../services/parent_service.dart';
import '../models/student.dart';
import '../theme.dart';

class TimetableScreen extends StatefulWidget {
  final Student child;
  const TimetableScreen({super.key, required this.child});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  final TimetableService _timetableService = TimetableService();
  final ParentService _parentService = ParentService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _timetable = [];
  String? _classId;
  String _section = '';
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _exams = [];
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClassAndSection();
  }

  Future<void> _loadClassAndSection() async {
    final level = widget.child.level;
    final section = widget.child.section ?? 'أ';

    if (level == null || level.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'الطالب غير مسجل في أي مستوى دراسي';
      });
      return;
    }

    // 1. محاولة المطابقة المباشرة
    var classData = await _parentService.getClassByName(level);
    // 2. البحث المرن (مثلاً "1" يطابق "الصف الأول")
    classData ??= await _parentService.getClassByLevelNumber(level);

    final cid = classData?['id'];
    if (cid == null) {
      setState(() {
        _isLoading = false;
        _error = 'لم يتم العثور على صف دراسي مطابق لـ: $level';
      });
      return;
    }

    setState(() {
      _classId = cid;
      _section = section;
    });
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final timetable = await _timetableService.getTimetableForClass(_classId!, _section);
      final tests = await _timetableService.getTestsForClass(_classId!, _section);
      final exams = await _timetableService.getExamsForClass(_classId!, _section);

      timetable.sort((a, b) {
        final dayComp = (a['day_of_week'] as int).compareTo(b['day_of_week'] as int);
        if (dayComp != 0) return dayComp;
        return (a['start_time'] as String).compareTo(b['start_time'] as String);
      });

      setState(() {
        _timetable = timetable;
        _tests = tests;
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTimetable {
    if (_selectedDay == null) return _timetable;
    return _timetable.where((item) => item['day_of_week'] == _selectedDay).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('الجداول - ${widget.child.name} (شعبة $_section)'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'الحصص', icon: Icon(Icons.schedule)),
            Tab(text: 'الاختبارات', icon: Icon(Icons.quiz)),
            Tab(text: 'الامتحانات', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimetableTab(),
                    _buildSimpleListTab(_tests, 'لا توجد اختبارات قصيرة',
                        Icons.quiz, AppTheme.success),
                    _buildSimpleListTab(_exams, 'لا توجد امتحانات',
                        Icons.assignment, AppTheme.error),
                  ],
                ),
    );
  }

  // ----- تبويب الحصص -----
  Widget _buildTimetableTab() {
    final now = DateTime.now();
    final today = (now.weekday % 7) + 1; // 1=السبت
    final tomorrow = today == 7 ? 1 : today + 1;

    final defaultList = _filteredTimetable
        .where((t) =>
            t['day_of_week'] == today || t['day_of_week'] == tomorrow)
        .toList();
    final displayed =
        _selectedDay != null ? _filteredTimetable : defaultList;

    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _dayChip('اليوم', today),
              _dayChip('غداً', tomorrow),
              const SizedBox(width: 8),
              ...List.generate(
                  7, (i) => _dayChip(_dayName(i + 1), i + 1)),
              const SizedBox(width: 8),
              _dayChip('كل الأيام', null),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: displayed.isEmpty
              ? Center(
                  child: Text('لا توجد حصص',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: displayed.length,
                  itemBuilder: (_, index) {
                    final item = displayed[index];
                    final lessonNumber = index + 1;
                    return _timetableCard(item, lessonNumber);
                  },
                ),
        ),
      ],
    );
  }

  Widget _dayChip(String label, int? day) {
    final selected = _selectedDay == day;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontSize: 13)),
        selected: selected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
        onSelected: (_) => setState(() => _selectedDay = day),
      ),
    );
  }

  Widget _timetableCard(Map<String, dynamic> item, int lessonNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: AppTheme.primary, size: 24),
                const SizedBox(height: 4),
                Text(
                  'ح $lessonNumber',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['subject_name'] ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['start_time'] ?? ''} - ${item['end_time'] ?? ''}',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _dayName(item['day_of_week']),
                style: TextStyle(color: AppTheme.primary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- تبويب الاختبارات والامتحانات -----
  Widget _buildSimpleListTab(List<Map<String, dynamic>> items,
      String emptyMsg, IconData icon, Color color) {
    if (items.isEmpty) {
      return Center(
          child: Text(emptyMsg,
              style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(item['test_name'] ?? item['exam_name'] ?? '',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${item['subject_name'] ?? ''}  •  ${item['test_date'] ?? item['exam_date'] ?? ''}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      },
    );
  }

  String _dayName(int day) {
    const days = [
      '',
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة'
    ];
    return days[day];
  }
}