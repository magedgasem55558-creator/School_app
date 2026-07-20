import 'dart:convert';
import 'package:flutter/material.dart';
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

  Future<void> _searchHadith(String query) async {
    if (query.trim().isEmpty) return;

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
                  onPressed: () => _searchController.clear(),
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
                    final hadithText = item['hadith'] ?? '';
                    final grade = item['grade'] ?? 'غير محدد';
                    final rawi = item['rawi'] ?? 'غير معروف';
                    final muhaddith = item['mukhrij'] ?? item['muhaddith'] ?? 'غير معروف';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(
                              hadithText,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(grade).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _getGradeColor(grade)),
                                  ),
                                  child: Text(
                                    'الحكم: $grade',
                                    style: TextStyle(color: _getGradeColor(grade), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text('الراوي: $rawi', style: TextStyle(color: Colors.grey.shade700)),
                                Text('المحدث: $muhaddith', style: TextStyle(color: Colors.grey.shade700)),
                              ],
                            ),
                          ],
                        ),
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
