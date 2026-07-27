import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class Reciter {
  final String id;
  final String name;
  final String serverUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.serverUrl,
  });
}

class YasserDossariQuranPage extends StatefulWidget {
  const YasserDossariQuranPage({Key? key}) : super(key: key);

  @override
  State<YasserDossariQuranPage> createState() => _YasserDossariQuranPageState();
}

class _YasserDossariQuranPageState extends State<YasserDossariQuranPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final List<Reciter> _reciters = const [
    Reciter(
      id: 'yasser',
      name: 'ياسر الدوسري',
      serverUrl: 'https://server11.mp3quran.net/yasser',
    ),
    Reciter(
      id: 'basit',
      name: 'عبد الباسط عبد الصمد (مرتل)',
      serverUrl: 'https://server7.mp3quran.net/basit',
    ),
    Reciter(
      id: 'afs',
      name: 'مشاري العفاسي',
      serverUrl: 'https://server8.mp3quran.net/afs',
    ),
    Reciter(
      id: 'maher',
      name: 'ماهر المعيقلي',
      serverUrl: 'https://server12.mp3quran.net/maher',
    ),
    Reciter(
      id: 'shur',
      name: 'سعود الشريم',
      serverUrl: 'https://server7.mp3quran.net/shur',
    ),
  ];

  late Reciter _selectedReciter;

  bool _isPlaying = false;
  int? _currentSurahIndex;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final Map<String, bool> _downloadedSurahs = {};
  final Map<String, double> _downloadProgress = {};

  final List<String> _surahNames = const [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
    "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
    "الأنبيـاء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
    "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
    "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
    "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
    "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
    "التكوير", "الانفطار", "المطففين", "الانشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
    "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
    "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "المعون", "الكوثر", "الكافرون", "النصر",
    "المسد", "الإخلاص", "الفلق", "الناس"
  ];

  @override
  void initState() {
    super.initState();
    _selectedReciter = _reciters[0];
    _checkDownloadedFiles();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getFileKey(Reciter reciter, int surahIndex) {
    return '${reciter.id}_${surahIndex + 1}';
  }

  String _getSurahUrl(Reciter reciter, int index) {
    String formattedIndex = (index + 1).toString().padLeft(3, '0');
    return '${reciter.serverUrl}/$formattedIndex.mp3';
  }

  Future<String> _getFilePath(Reciter reciter, int index) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/surah_${_getFileKey(reciter, index)}.mp3';
  }

  Future<void> _checkDownloadedFiles() async {
    for (var reciter in _reciters) {
      for (int i = 0; i < _surahNames.length; i++) {
        String path = await _getFilePath(reciter, i);
        if (File(path).existsSync()) {
          _downloadedSurahs[_getFileKey(reciter, i)] = true;
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _downloadSurah(int index) async {
    final fileKey = _getFileKey(_selectedReciter, index);
    String url = _getSurahUrl(_selectedReciter, index);
    String savePath = await _getFilePath(_selectedReciter, index);

    try {
      Dio dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (rec, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[fileKey] = rec / total;
            });
          }
        },
      );
      setState(() {
        _downloadedSurahs[fileKey] = true;
        _downloadProgress.remove(fileKey);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل سورة ${_surahNames[index]} بصوت ${_selectedReciter.name} بنجاح!')),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(fileKey);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التنزيل!')),
        );
      }
    }
  }

  Future<void> _playSurah(int index) async {
    final fileKey = _getFileKey(_selectedReciter, index);

    if (_currentSurahIndex == index) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    await _audioPlayer.stop();
    _currentSurahIndex = index;
    String filePath = await _getFilePath(_selectedReciter, index);

    if (_downloadedSurahs[fileKey] == true && File(filePath).existsSync()) {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } else {
      await _audioPlayer.play(UrlSource(_getSurahUrl(_selectedReciter, index)));
    }
  }

  void _seek(int seconds) {
    Duration newPosition = _position + Duration(seconds: seconds);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > _duration) newPosition = _duration;
    _audioPlayer.seek(newPosition);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصحف الشريف'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.teal),
                const SizedBox(width: 10),
                const Text(
                  'اختر القارئ: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Reciter>(
                      value: _selectedReciter,
                      isExpanded: true,
                      items: _reciters.map((Reciter reciter) {
                        return DropdownMenuItem<Reciter>(
                          value: reciter,
                          child: Text(
                            reciter.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (Reciter? newReciter) async {
                        if (newReciter != null && newReciter != _selectedReciter) {
                          await _audioPlayer.stop();
                          setState(() {
                            _selectedReciter = newReciter;
                            _currentSurahIndex = null;
                            _isPlaying = false;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _surahNames.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final isCurrent = _currentSurahIndex == index;
                final fileKey = _getFileKey(_selectedReciter, index);
                final isDownloaded = _downloadedSurahs[fileKey] == true;
                final isDownloading = _downloadProgress.containsKey(fileKey);

                return ListTile(
                  selected: isCurrent,
                  selectedTileColor: Colors.teal.shade50,
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? Colors.teal : Colors.teal.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'سورة ${_surahNames[index]}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isDownloaded ? 'مُحملة (بدون إنترنت)' : 'القارئ: ${_selectedReciter.name}',
                    style: TextStyle(color: isDownloaded ? Colors.green : Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDownloading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _downloadProgress[fileKey],
                            strokeWidth: 3,
                          ),
                        )
                      else if (!isDownloaded)
                        IconButton(
                          icon: const Icon(Icons.download_for_offline_outlined, color: Colors.teal),
                          onPressed: () => _downloadSurah(index),
                        )
                      else
                        const Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        icon: Icon(
                          (isCurrent && _isPlaying)
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.teal,
                          size: 36,
                        ),
                        onPressed: () => _playSurah(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_currentSurahIndex != null)
            Container(
              color: Colors.teal.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'سورة ${_surahNames[_currentSurahIndex!]} - ${_selectedReciter.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    activeColor: Colors.teal.shade200,
                    inactiveColor: Colors.white30,
                    min: 0.0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatTime(_position), style: const TextStyle(color: Colors.white70)),
                        Text(_formatTime(_duration), style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                        onPressed: () => _seek(-10),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () => _playSurah(_currentSurahIndex!),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                        onPressed: () => _seek(10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
