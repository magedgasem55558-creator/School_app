import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class HadithSearchPage extends StatefulWidget {
  const HadithSearchPage({Key? key}) : super(key: key);

  @override
  State<HadithSearchPage> createState() => _HadithSearchPageState();
}

class _HadithSearchPageState extends State<HadithSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchHadith(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    // إخفاء لوحة المفاتيح عند بدء البحث
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      // 1. الاتصال المباشر مع API الدرر السنية الرسمي
      final url = Uri.parse(
        'https://dorar-hadith-api.dorar.net/api/hadith/search?value=${Uri.encodeComponent(cleanQuery)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['ahadith'] ?? data['data'] ?? [];

        if (items.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم العثور على أحاديث تطابق كلمة البحث.';
            _isLoading = false;
          });
          return;
        }

        List<Map<String, String>> parsedResults = items.map((item) {
          return {
            'hadith': _cleanHtml(item['hadith'] ?? item['text'] ?? ''),
            'grade': _cleanHtml(item['grade'] ?? item['degree'] ?? 'غير محدد'),
            'rawi': _cleanHtml(item['rawi'] ?? item['el_rawi'] ?? 'غير معروف'),
            'muhaddith': _cleanHtml(item['muhaddith'] ?? item['el_mohdith'] ?? 'غير معروف'),
            'source': _cleanHtml(item['source'] ?? item['book'] ?? ''),
          };
        }).toList();

        setState(() {
          _searchResults = parsedResults;
          _isLoading = false;
        });
      } else {
        await _fallbackSearch(cleanQuery);
      }
    } catch (e) {
      await _fallbackSearch(cleanQuery);
    }
  }

  // 2. المحرك الاحتياطي المباشر لموقع الدرر السنية (في حال تعثر الأولي)
  Future<void> _fallbackSearch(String query) async {
    try {
      final fallbackUrl = Uri.parse(
        'https://dorar.net/dorar_api.json?skey=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(fallbackUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String htmlContent = data['ahadith']?['result'] ?? '';

        if (htmlContent.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم العثور على نتائج للبحث.';
            _isLoading = false;
          });
          return;
        }

        List<Map<String, String>> results = _parseDorarHtml(htmlContent);

        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'تعذر الاتصال بخدمة البحث حالياً، يرجى إعادة المحاولة.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالشبكة، تأكد من اتصال جهازك بالإنترنت.';
        _isLoading = false;
      });
    }
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'style="[^"]*"'), '')
        .replaceAll(RegExp(r"style='[^']*'"), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Map<String, String>> _parseDorarHtml(String html) {
    List<Map<String, String>> list = [];
    final hadithBlocks = html.split('<div class="hadith"');

    for (var block in hadithBlocks) {
      if (!block.contains('</div>')) continue;

      String hadithText = _cleanHtml(block);
      if (hadithText.length > 10) {
        list.add({
          'hadith': hadithText,
          'grade': 'راجع النص',
          'rawi': 'الموسوعة الحديثية',
          'muhaddith': 'الدرر السنية',
          'source': '',
        });
      }
    }
    return list;
  }

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح') || grade.contains('حسن')) {
      return Colors.green.shade700;
    } else if (grade.contains('ضعيف') || grade.contains('منكر')) {
      return Colors.orange.shade800;
    } else if (grade.contains('باطل') || grade.contains('موضوع') || grade.contains('لا أصل له')) {
      return Colors.red.shade700;
    }
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من صحة الحديث'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'اكتب نص الحديث أو كلمة منه...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _errorMessage = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) => _searchHadith(value),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _searchHadith(_searchController.text),
              child: const Text('بحث في الموسوعة الحديثية', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: Colors.teal)),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16, height: 1.4),
                    ),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              const Expanded(
                child: Center(child: Text('ابحث عن أي حديث للتحقق من درجة صحته', style: TextStyle(color: Colors.grey, fontSize: 16))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return HadithCardItem(
                      hadithText: item['hadith'] ?? '',
                      grade: item['grade'] ?? 'غير محدد',
                      rawi: item['rawi'] ?? 'غير معروف',
                      muhaddith: item['muhaddith'] ?? 'غير معروف',
                      source: item['source'] ?? '',
                      gradeColor: _getGradeColor(item['grade'] ?? ''),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HadithCardItem extends StatefulWidget {
  final String hadithText;
  final String grade;
  final String rawi;
  final String muhaddith;
  final String source;
  final Color gradeColor;

  const HadithCardItem({
    Key? key,
    required this.hadithText,
    required this.grade,
    required this.rawi,
    required this.muhaddith,
    required this.source,
    required this.gradeColor,
  }) : super(key: key);

  @override
  State<HadithCardItem> createState() => _HadithCardItemState();
}

class _HadithCardItemState extends State<HadithCardItem> {
  bool _isExpanded = false;
  static const int _maxTrimLength = 180;

  @override
  Widget build(BuildContext context) {
    final bool isLongText = widget.hadithText.length > _maxTrimLength;
    final String displayText = (_isExpanded || !isLongText)
        ? widget.hadithText
        : '${widget.hadithText.substring(0, _maxTrimLength)}...';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isLongText)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.teal,
                    size: 20,
                  ),
                  label: Text(
                    _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const Divider(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.gradeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.gradeColor),
                  ),
                  child: Text(
                    'الحكم: ${widget.grade}',
                    style: TextStyle(
                      color: widget.gradeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'الراوي: ${widget.rawi}',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'المحدث: ${widget.muhaddith}',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (widget.source.isNotEmpty)
                  Text(
                    'المصدر: ${widget.source}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomLeft,
              child: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                tooltip: 'نسخ الحديث',
                onPressed: () {
                  final fullData = '''${widget.hadithText}
الراوي: ${widget.rawi}
المحدث: ${widget.muhaddith}
خلاصة حكم الحديث: ${widget.grade}${widget.source.isNotEmpty ? '\nالمصدر: ' + widget.source : ''}''';
                  Clipboard.setData(ClipboardData(text: fullData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ نص الحديث والمعلومات إلى الحافظة'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
