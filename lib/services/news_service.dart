import 'api_service.dart';

class NewsService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final data = await _api.get('announcements');
    data.sort((a, b) {
      final pinnedCompare = (b['is_pinned'] == true ? 1 : 0)
          .compareTo(a['is_pinned'] == true ? 1 : 0);
      if (pinnedCompare != 0) return pinnedCompare;
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    return data;
  }
}