import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام Clipboard

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("تبرع للمسجد"),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('settings')
            .doc('donation_info')
            .get(),
        builder: (context, snapshot) {
          // بيانات افتراضية في حال عدم وجود البيانات
          String bankName = 'بنك الكريمي';
          String accountNumber = '123456789';
          String transferName = 'باسم إدارة مسجدنا';
          String phone = '779626069';
          String hadith = 'قال رسول الله ﷺ:\n(مَنْ بَنَى مَسْجِدًا بَنَى اللَّهُ لَهُ مِثْلَهُ فِي الْجَنَّةِ)';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            bankName = data['bankName'] ?? bankName;
            accountNumber = data['accountNumber'] ?? accountNumber;
            transferName = data['transferName'] ?? transferName;
            phone = data['phone'] ?? phone;
            hadith = data['hadith'] ?? hadith;
          }

          return Stack(
            children: [
              // خلفية بلون بنفسجي غامق (بدون صور)
              Container(color: const Color(0xFF1A002D)),
              // تأثير بسيط
              Container(color: Colors.black.withOpacity(0.5)),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.pinkAccent, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      hadith,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    _buildDonationMethod(context, "عبر $bankName", accountNumber, Icons.account_balance),
                    const SizedBox(height: 15),
                    _buildDonationMethod(context, "عبر الموحدة للحوالات", transferName, Icons.send),

                    const SizedBox(height: 40),
                    Text("تواصل مع لجنة المسجد: $phone",
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonationMethod(BuildContext context, String title, String detail, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: detail));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ النص')));
            },
          ),
        ],
      ),
    );
  }
}