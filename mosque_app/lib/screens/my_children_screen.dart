// lib/screens/my_children_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'child_details_screen.dart';

class MyChildrenScreen extends StatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  final service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("يرجى تسجيل الدخول")));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("أبنائي في المسجد", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1542834759-429337586071?q=80&w=2070'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamMyChildren(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("خطأ: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("لا يوجد أبناء مسجلين", style: TextStyle(color: Colors.white70)),
                  );
                }
                final children = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    return _buildChildCard(context, children[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- بناء بطاقة الطفل مع جلب اسم الحلقة بشكل منفصل ---
  Widget _buildChildCard(BuildContext context, Map<String, dynamic> child) {
    // استخراج halaqaId من الحقل (قد يكون String أو DocumentReference)
    dynamic halaqaField = child['halaqaId'];
    String? halaqaId;
    if (halaqaField is DocumentReference) {
      halaqaId = halaqaField.id;
    } else if (halaqaField is String) {
      halaqaId = halaqaField;
    }

    // إذا لم يكن هناك halaqaId، نعرض "غير محددة" مباشرة
    if (halaqaId == null || halaqaId.isEmpty) {
      return _buildCardLayout(child, 'غير محددة');
    }

    // جلب اسم الحلقة داخل FutureBuilder
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('halaqat').doc(halaqaId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCardLayout(child, 'جاري التحميل...');
        }
        if (snapshot.hasError) {
          debugPrint('❌ خطأ في جلب الحلقة $halaqaId: ${snapshot.error}');
          return _buildCardLayout(child, 'خطأ في الجلب');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('❌ الحلقة $halaqaId غير موجودة');
          return _buildCardLayout(child, 'حلقة محذوفة');
        }

        final halaqaData = snapshot.data!.data() as Map<String, dynamic>;
        final halaqaName = halaqaData['name'] as String? ?? 'غير محدد';
        debugPrint('✅ تم جلب الحلقة: $halaqaName لابن: ${child['name']}');
        return _buildCardLayout(child, halaqaName);
      },
    );
  }

  // --- الواجهة المشتركة للبطاقة ---
  Widget _buildCardLayout(Map<String, dynamic> child, String halaqaName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.tealAccent,
          child: Text(
            (child['name'] != null && child['name'].isNotEmpty)
                ? child['name']![0].toUpperCase()
                : "?",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        title: Text(
          child['name'] ?? "اسم غير معروف",
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInfoTag(Icons.star, "${child['totalPoints'] ?? 0} نقطة", Colors.amberAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    "الحلقة: $halaqaName",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "انضم في: ${child['joinDate'] != null ? (child['joinDate'] as Timestamp).toDate().toString().split(' ')[0] : 'غير معروف'}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: child['isActive'] == true ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    child['isActive'] == true ? "نشط" : "متوقف",
                    style: TextStyle(
                      color: child['isActive'] == true ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildDetailsScreen(child: child),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}