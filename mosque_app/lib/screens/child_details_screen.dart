import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChildDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> child;

  const ChildDetailsScreen({super.key, required this.child});

  // دالة مساعدة لاستخراج halaqaId سواء كان نصاً أو مرجعاً
  String? _getHalaqaId() {
    dynamic halaqaField = child['halaqaId'];
    if (halaqaField is DocumentReference) {
      return halaqaField.id;
    } else if (halaqaField is String) {
      return halaqaField;
    }
    return null;
  }

  // جلب رقم جوال المعلم من وثيقة الحلقة
  Future<String?> _fetchTeacherPhone() async {
    final String? halaqaId = _getHalaqaId();
    if (halaqaId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('halaqat')
          .doc(halaqaId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['teacherPhone'] as String?;
      }
    } catch (e) {
      debugPrint('خطأ في جلب بيانات المعلم: $e');
    }
    return null;
  }

  // فتح واتساب مع المعلم
  Future<void> _openWhatsApp(BuildContext context) async {
    // عرض مؤثر تحميل أثناء الجلب
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
    );

    final phone = await _fetchTeacherPhone();
    if (context.mounted) Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم المعلم غير متوفر حالياً')),
        );
      }
      return;
    }

    final message = "السلام عليكم.. أستفسر عن مستوى ابني ${child['name'] ?? 'الطالب'} في حلقة القرآن";
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? studentId = child['id'] as String?;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("متابعة ${child['name'] ?? 'الطالب'}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          // زر ثابت للتواصل مع المعلم في شريط العنوان
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.greenAccent),
              tooltip: 'تواصل مع المعلم',
              onPressed: () => _openWhatsApp(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "إنجاز اليوم", icon: Icon(Icons.today)),
              Tab(text: "أعمال الشهر", icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(color: const Color(0xFF1A002D)),
            Container(color: Colors.black.withOpacity(0.7)),
            if (studentId == null)
              const Center(child: Text("خطأ في معرف الطالب", style: TextStyle(color: Colors.red)))
            else
              TabBarView(
                children: [
                  _buildDailyReport(studentId),
                  _buildMonthlyReport(studentId),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport(String studentId) {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('records')
          .where('studentId', isEqualTo: studentId)
          .where('date', isEqualTo: today)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("لا يوجد إنجاز مسجل لتاريخ اليوم\n($today)", 
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 16)));
        }
        return _buildRecordList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildMonthlyReport(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('records')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("لا توجد سجلات سابقة", style: TextStyle(color: Colors.white60)));
        }
        List<DocumentSnapshot> docs = snapshot.data!.docs;
        docs.sort((a, b) => (b.get('date') ?? "").compareTo(a.get('date') ?? ""));
        return _buildRecordList(docs);
      },
    );
  }

  Widget _buildRecordList(List<DocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 180, left: 20, right: 20, bottom: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        String status = data['status'] ?? "حاضر";
        bool isSpecialStatus = status == "غائب" || status == "إجازة";

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: status == "غائب" ? Colors.red.withOpacity(0.15) : 
                   status == "إجازة" ? Colors.blue.withOpacity(0.15) : 
                   Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  isSpecialStatus ? "الحالة: $status" : "سورة ${data['surah'] ?? 'غير محددة'}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: isSpecialStatus ? null : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("من آية ${data['fromAyah'] ?? '0'} إلى ${data['toAyah'] ?? '0'}",
                      style: const TextStyle(color: Colors.white60)),
                ),
                trailing: Text(data['date'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ),
              
              if (!isSpecialStatus)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEvaluationTag("إتقان", (data['grade'] ?? "").toString().contains("إتقان")),
                        _buildEvaluationTag("حفظ", (data['grade'] ?? "").toString().contains("حفظ")),
                        _buildEvaluationTag("تجويد", (data['grade'] ?? "").toString().contains("تجويد")),
                      ],
                    ),
                  ),
                ),

              if (data['tomorrowRequirement'] != null || data['notes'] != null)
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      if (data['tomorrowRequirement'] != null && data['tomorrowRequirement'] != "")
                        _buildInfoRow(Icons.auto_stories, "المطلوب غداً:", data['tomorrowRequirement']),
                      if (data['notes'] != null && data['notes'] != "")
                        _buildInfoRow(Icons.edit_note, "ملاحظة المدرس:", data['notes']),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationTag(String title, bool isDone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.cancel,
          color: isDone ? Colors.greenAccent : Colors.redAccent.withOpacity(0.4),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isDone ? Colors.white : Colors.white38,
            fontSize: 13,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.tealAccent),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "$label ", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}