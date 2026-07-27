class Reciter {
  final String name;
  final String identifier; // مثل "ar.mahermuaiqly" أو "ar.yasserdosari"
  final String baseUrl;

  Reciter({required this.name, required this.identifier})
      : baseUrl = 'https://api.alquran.cloud/v1/quran/$identifier';
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final int ayahsCount;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.ayahsCount,
  });

  // تم تحسين الـ Factory ليكون آمناً بالكامل ضد القيم الفارغة أو تحويل الأنواع
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] is int ? json['number'] : int.parse(json['number']?.toString() ?? '0'),
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      ayahsCount: json['numberOfAyahs'] is int ? json['numberOfAyahs'] : int.parse(json['numberOfAyahs']?.toString() ?? '0'),
    );
  }
}