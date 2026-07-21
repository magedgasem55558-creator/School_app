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

  // دالة تنظيف النصوص من أوسمة HTML والأرقام والرموز الزائدة
  String _cleanText(String rawText) {
    if (rawText.isEmpty) return '';

    String text = rawText;

    // 1. إزالة أوسمة HTML مثل <p>, <span>, <br>, <b>
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 2. إزالة الأرقام والأصوات المرجعية مثل <1> أو [1] أو (1)
    text = text.replaceAll(RegExp(r'[\(\[\<]\d+[\)\]\>]'), '');

    // 3. تنظيف عبارات الوسوم والمواضع المكررة
    text = text.replaceAll('الموسوعة الحديثية', '');
    text = text.replaceAll('الموقع الرسمي للموسوعة الحديثية', '');

    // 4. تحويل الكيانات المصرحة (HTML entities)
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<');

    // 5. إزالة المسافات والرموز المتروكة في بداية ونهاية النص
    text = text.replaceAll(RegExp(r'^[\s\:\-\_]+'), '');

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
      final url = Uri.parse('https://dorar-hadith-api.almts.mobi/api/hadith/search?value=${Uri.encodeComponent(query)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'حدث خطأ في الاتصال بالخادم';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالشبكة، تحقق من اتصالك بالإنترنت';
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
                child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16))),
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
                    
                    // تنظيف القيم قبل العرض
                    final hadithText = _cleanText(item['hadith'] ?? '');
                    final grade = _cleanText(item['grade'] ?? 'غير محدد');
                    final rawi = _cleanText(item['rawi'] ?? 'غير معروف');
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

// ويدجت مستقلا لإدارة حالة التوسيع للحديث الطويل بدعم زر "عرض المزيد / عرض أقل"
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
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // نص الحديث التفاعلي
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
            
            // زر عرض المزيد / عرض أقل عند كبر نص الحديث
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

            // معلومات درجة الحديث والراوي والمحدث
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

            // زر نسخ الحديث
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
