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
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // دالة تنظيف النصوص من أوسمة HTML والرموز
  String _cleanText(String rawText) {
    if (rawText.isEmpty) return '';

    String text = rawText;
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll(RegExp(r'[\(\[\<]\d+[\)\]\>]'), '');
    text = text.replaceAll('الموسوعة الحديثية', '');
    text = text.replaceAll('الموقع الرسمي للموسوعة الحديثية', '');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<');

    return text.trim();
  }

  Future<void> _searchHadith(String query) async {
    if (query.trim().isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      // 1. تجربة API الدرر السنية المباشر والمستقر
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        'https://dorar-hadith-api.herokuapp.com/api/hadith/search?value=$encodedQuery',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // التأكد من أن النتيجة بصيغة JSON وليست صفحة HTML
        if (response.body.startsWith('{') || response.body.startsWith('[')) {
          final decodedData = json.decode(response.body);

          List<dynamic> results = [];
          if (decodedData is List) {
            results = decodedData;
          } else if (decodedData is Map<String, dynamic>) {
            results = decodedData['data'] ?? decodedData['results'] ?? [];
          }

          if (results.isEmpty) {
            setState(() {
              _errorMessage = 'لم يتم العثور على أحاديث تطابق كلمة البحث';
              _isLoading = false;
            });
          } else {
            setState(() {
              _searchResults = results;
              _isLoading = false;
            });
          }
        } else {
          await _fetchFromSecondaryApi(query);
        }
      } else {
        await _fetchFromSecondaryApi(query);
      }
    } catch (e) {
      await _fetchFromSecondaryApi(query);
    }
  }

  // خادم احتياطي في حال تعثر الأول
  Future<void> _fetchFromSecondaryApi(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final fallbackUrl = Uri.parse(
        'https://dorar-hadith-api.almts.mobi/api/hadith/search?value=$encodedQuery',
      );

      final response = await http.get(
        fallbackUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && (response.body.startsWith('{') || response.body.startsWith('['))) {
        final data = json.decode(response.body);
        List<dynamic> results = [];

        if (data is Map<String, dynamic>) {
          results = data['data'] ?? [];
        } else if (data is List) {
          results = data;
        }

        if (results.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم العثور على نتائج للبحث، جرب كلمات أخرى من الحديث';
            _isLoading = false;
          });
        } else {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'سيرفر البحث متوقف حالياً، يرجى المحاولة لاحقاً';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالشبكة، تأكد من اتصال جهازك بالإنترنت';
        _isLoading = false;
      });
    }
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
                      style: const TextStyle(color: Colors.red, fontSize: 16, height: 1.4),
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

                    final hadithText = _cleanText(item['hadith'] ?? item['text'] ?? '');
                    final grade = _cleanText(item['grade'] ?? item['hadithGrade'] ?? 'غير محدد');
                    final rawi = _cleanText(item['rawi'] ?? item['narrator'] ?? 'غير معروف');
                    final muhaddith = _cleanText(item['mukhrij'] ?? item['muhaddith'] ?? 'غير معروف');
                    final source = _cleanText(item['source'] ?? item['book'] ?? '');

                    return HadithCardItem(
                      hadithText: hadithText,
                      grade: grade,
                      rawi: rawi,
                      muhaddith: muhaddith,
                      source: source,
                      gradeColor: _getGradeColor(grade),
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
خلاصة حكم الحديث: ${widget.grade}''';
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
