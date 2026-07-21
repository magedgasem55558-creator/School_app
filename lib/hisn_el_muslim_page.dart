import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AzkarData {
  static const List<Map<String, dynamic>> categories = [
    {
      'title': 'أذكار الصباح',
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.amber,
      'items': [
        {'text': 'أَصْبَحْنَا وَأَصْبَحَ المُلْكُ لِلَّهِ وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ.', 'count': 1},
        {'text': 'آية الكرسي: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...', 'count': 1},
        {'text': 'قُلْ هُوَ اللَّهُ أَحَدٌ... (سورة الإخلاص)', 'count': 3},
        {'text': 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ... (سورة الفلق)', 'count': 3},
        {'text': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ... (سورة الناس)', 'count': 3},
        {'text': 'رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيّاً.', 'count': 3},
        {'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.', 'count': 3},
      ]
    },
    {
      'title': 'أذكار المساء',
      'icon': Icons.nights_stay_rounded,
      'color': Colors.indigo,
      'items': [
        {'text': 'أَمْسَيْنَا وَأَمْسَى المُلْكُ لِلَّهِ وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ.', 'count': 1},
        {'text': 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ المَصِيرُ.', 'count': 1},
        {'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.', 'count': 3},
        {'text': 'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ العَلِيمُ.', 'count': 3},
      ]
    },
    {
      'title': 'أذكار النوم',
      'icon': Icons.bedtime_rounded,
      'color': Colors.deepPurple,
      'items': [
        {'text': 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.', 'count': 1},
        {'text': 'اللَّهُمَّ خَلَقْتَ نَفْسِي وَأَنْتَ تَتَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْيَاهَا...', 'count': 1},
        {'text': 'سُبْحَانَ اللَّهِ (33)، وَالحَمْدُ لِلَّهِ (33)، وَاللَّهُ أَكْبَرُ (34).', 'count': 100},
      ]
    },
    {
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.wb_twilight_rounded,
      'color': Colors.orange,
      'items': [
        {'text': 'الحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.', 'count': 1},
        {'text': 'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', 'count': 1},
      ]
    },
    {
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque_rounded,
      'color': Colors.teal,
      'items': [
        {'text': 'أَسْتَغْفِرُ اللَّهَ (ثَلاَثاً)... اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ، تَبَارَكْتَ يَا ذَا الجَلاَلِ وَالإِكْرَامِ.', 'count': 1},
        {'text': 'سُبْحَانَ اللَّهِ (33)، الحَمْدُ لِلَّهِ (33)، اللَّهُ أَكْبَرُ (33).', 'count': 99},
        {'text': 'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', 'count': 1},
      ]
    },
    {
      'title': 'أدعية قرآنيّة',
      'icon': Icons.menu_book_rounded,
      'color': Colors.teal, // تم التعديل من emerald إلى teal
      'items': [
        {'text': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.', 'count': 1},
        {'text': 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي.', 'count': 1},
        {'text': 'رَبَّنَا لاَ تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً.', 'count': 1},
      ]
    },
    {
      'title': 'أدعية للمريض',
      'icon': Icons.healing_rounded,
      'color': Colors.redAccent,
      'items': [
        {'text': 'لاَ بَأْسَ طَهُورٌ إِنْ شَاءَ اللَّهُ.', 'count': 1},
        {'text': 'أَسْأَلُ اللَّهَ العَظِيمَ رَبَّ العَرْشِ العَظِيمِ أَنْ يَشْفِيَكَ.', 'count': 7},
      ]
    },
    {
      'title': 'أدعية السفر',
      'icon': Icons.connecting_airports_rounded,
      'color': Colors.blue,
      'items': [
        {'text': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ.', 'count': 1},
        {'text': 'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا البِرَّ وَالتَّقْوَى، وَمِنَ العَمَلِ مَا تَرْضَى.', 'count': 1},
      ]
    },
  ];
}

class HisnElMuslimPage extends StatelessWidget {
  const HisnElMuslimPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'حصن المسلم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'أَلا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'اختر التصنيف لقراءة الأذكار واستخدام العداد التفاعلي',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: AzkarData.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final cat = AzkarData.categories[index];
                  final Color catColor = cat['color'] as Color;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AzkarDetailPage(
                            title: cat['title'],
                            items: List<Map<String, dynamic>>.from(cat['items']),
                            themeColor: catColor,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: catColor.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: catColor.withOpacity(0.2), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: catColor.withOpacity(0.15),
                            child: Icon(cat['icon'], color: catColor, size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cat['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(cat['items'] as List).length} أذكار',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AzkarDetailPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Color themeColor;

  const AzkarDetailPage({
    Key? key,
    required this.title,
    required this.items,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<AzkarDetailPage> createState() => _AzkarDetailPageState();
}

class _AzkarDetailPageState extends State<AzkarDetailPage> {
  late List<int> _counters;

  @override
  void initState() {
    super.initState();
    _counters = widget.items.map((e) => e['count'] as int).toList();
  }

  void _decrementCounter(int index) {
    if (_counters[index] > 0) {
      setState(() {
        _counters[index]--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.themeColor,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final currentCount = _counters[index];
          final isCompleted = currentCount == 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item['text'],
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.grey : Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.grey),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item['text']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الذكر إلى الحافظة'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      InkWell(
                        onTap: () => _decrementCounter(index),
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.shade300
                                : widget.themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isCompleted ? Colors.grey : widget.themeColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                color: isCompleted ? Colors.grey : widget.themeColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isCompleted ? 'تم' : 'المتبقي: $currentCount',
                                style: TextStyle(
                                  color: isCompleted ? Colors.grey : widget.themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
