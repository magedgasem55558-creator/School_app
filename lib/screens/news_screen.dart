import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/news_service.dart';
import '../theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _newsService.getAnnouncements();
      if (mounted) setState(() { _announcements = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('الأخبار والإعلانات'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('حدث خطأ: $_error', style: TextStyle(color: AppTheme.error), textAlign: TextAlign.center),
                ))
              : _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('لا توجد إعلانات حالياً', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) => _buildCard(_announcements[index]),
                    ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isPinned = item['is_pinned'] == true;
    final createdAt = item['created_at'] != null
        ? DateFormat('yyyy/MM/dd – hh:mm a', 'ar').format(DateTime.parse(item['created_at']))
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isPinned ? Icons.push_pin : Icons.campaign,
          color: isPinned ? AppTheme.warning : AppTheme.primary,
        ),
        title: Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
        subtitle: createdAt.isNotEmpty ? Text(createdAt, style: Theme.of(context).textTheme.bodySmall) : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(item['content'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}