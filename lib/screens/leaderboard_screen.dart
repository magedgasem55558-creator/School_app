import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("لوحة المتصدرين"), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1590076215667-873d47343e06?q=80&w=2070'), fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withOpacity(0.7))),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('students').orderBy('totalPoints', descending: true).limit(10).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final students = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index].data() as Map<String, dynamic>;
                  bool isTop3 = index < 3;
                  return _buildLeaderCard(index + 1, data['name'], data['totalPoints'] ?? 0, isTop3);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(int rank, String name, int points, bool isTop3) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTop3 ? Colors.tealAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isTop3 ? Colors.tealAccent : Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTop3 ? Colors.amber : Colors.blueGrey,
          child: Text(rank.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: Text("$points نقطة", style: const TextStyle(color: Colors.tealAccent, fontSize: 16)),
      ),
    );
  }
}