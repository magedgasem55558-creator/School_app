import 'package:cloud_firestore/cloud_firestore.dart';

// نموذج الفعالية القادمة
class NextEvent {
  final String title;
  final String location;
  final String date;
  final DateTime lastUpdated;

  NextEvent({required this.title, required this.location, required this.date, required this.lastUpdated});

  factory NextEvent.fromFirestore(Map<String, dynamic> data) {
    return NextEvent(
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

// نموذج خطبة الجمعة
class NextKhutba {
  final String title;
  final String imam;
  final DateTime lastUpdated;

  NextKhutba({required this.title, required this.imam, required this.lastUpdated});

  factory NextKhutba.fromFirestore(Map<String, dynamic> data) {
    return NextKhutba(
      title: data['title'] ?? '',
      imam: data['imam'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}