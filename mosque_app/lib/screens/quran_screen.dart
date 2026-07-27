import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // ✅ استيراد حزمة تشغيل الخلفية
import '../services/quran_data.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  
  // خريطة لمتابعة حالة ونسبة التحميل لكل سورة بناءً على الـ ID
  final Map<int, double> _downloadProgress = {};
  final Map<int, bool> _isDownloaded = {};

  int? _currentlyPlayingSurahId;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkDownloadedSurahs();
    
    // الاستماع لحالة مشغل الصوتيات وتحديث الواجهة تلقائياً
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _dio.close();
    super.dispose();
  }

  // التحقق من السور المحملة مسبقاً من الـ Preferences
  Future<void> _checkDownloadedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();

    for (var surah in QuranData.surahs) {
      int id = surah['id'];
      String path = '${appDir.path}/surah_$id.mp3';
      bool exists = await File(path).exists();
      
      setState(() {
        _isDownloaded[id] = exists;
      });
      
      // تأكيد التزامن مع الخصائص المحفوظة
      if (exists) {
        await prefs.setBool('downloaded_$id', true);
      } else {
        await prefs.remove('downloaded_$id');
      }
    }
  }

  // منطق تحميل السورة وحفظها محلياً
  Future<void> _downloadSurah(int id, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      String savePath = '${appDir.path}/surah_$id.mp3';
      String url = '${QuranData.audioBaseUrl}$fileName';

      setState(() {
        _downloadProgress[id] = 0.0;
      });

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[id] = received / total;
            });
          }
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloaded_$id', true);

      setState(() {
        _isDownloaded[id] = true;
        _downloadProgress.remove(id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل السورة بنجاح ويمكنك الاستماع إليها دون نت.')),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحميل، يرجى التحقق من الاتصال: $e')),
        );
      }
    }
  }

  // حذف السورة المحملة لتوفير مساحة التخزين
  Future<void> _deleteSurah(int id) async {
    final appDir = await getApplicationDocumentsDirectory();
    String path = '${appDir.path}/surah_$id.mp3';
    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('downloaded_$id');

    setState(() {
      _isDownloaded[id] = false;
      if (_currentlyPlayingSurahId == id) {
        _audioPlayer.stop();
        _currentlyPlayingSurahId = null;
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الملف المحلي لسورة بنجاح.')),
      );
    }
  }

  // منطق تشغيل السورة (أوفلاين أو أونلاين) مع دعم الخلفية
  Future<void> _playSurah(Map<String, dynamic> surah) async {
    int id = surah['id'];
    String fileName = surah['fileName'];
    bool offline = _isDownloaded[id] ?? false;

    if (_currentlyPlayingSurahId == id) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingSurahId = id;
        _position = Duration.zero;
        _duration = Duration.zero;
      });

      // إعداد كائن البيانات التوضيحي لشاشة القفل والإشعارات
      final mediaItem = MediaItem(
        id: 'surah_$id',
        album: "القرآن الكريم",
        title: surah['name'],
        artist: "القارئ: ياسر الدوسري",
        artUri: Uri.parse('asset:///assets/images/logo.png'), // شعار المسجد كصورة غلاف للصوت
      );

      if (offline) {
        final appDir = await getApplicationDocumentsDirectory();
        String localPath = '${appDir.path}/surah_$id.mp3';
        // ✅ تمرير الـ tag لتشغيل الملف المحلي في الخلفية
        await _audioPlayer.setAudioSource(
          AudioSource.file(
            localPath,
            tag: mediaItem,
          ),
        );
      } else {
        String url = '${QuranData.audioBaseUrl}$fileName';
        // ✅ تمرير الـ tag لتشغيل الرابط أونلاين في الخلفية
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: mediaItem,
          ),
        );
      }
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تشغيل الملف الصوتي: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم - ياسر الدوسري'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Column(
        children: [
          // قائمة السور
          Expanded(
            child: ListView.builder(
              itemCount: QuranData.surahs.length,
              itemBuilder: (context, index) {
                final surah = QuranData.surahs[index];
                int id = surah['id'];
                bool isDownloaded = _isDownloaded[id] ?? false;
                bool isDownloading = _downloadProgress.containsKey(id);
                bool isCurrent = _currentlyPlayingSurahId == id;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: isCurrent ? Colors.teal.shade900.withOpacity(0.4) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.tealAccent.shade700,
                      child: Text(
                        '$id',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      surah['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('عدد الآيات: ${surah['verses']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة تشغيل / إيقاف مؤقت
                        IconButton(
                          icon: Icon(
                            isCurrent && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            color: Colors.tealAccent,
                            size: 32,
                          ),
                          onPressed: () => _playSurah(surah),
                        ),
                        // حالة التحميل (زر تحميل، مؤشر نسبة مئوية، زر الحذف)
                        isDownloading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _downloadProgress[id],
                                  color: Colors.tealAccent,
                                  strokeWidth: 3,
                                ),
                              )
                            : isDownloaded
                                ? IconButton(
                                    icon: const Icon(Icons.cloud_done, color: Colors.green),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('حذف السورة المحملة'),
                                          content: Text('هل تريد حذف ملف سورة ${surah['name']} المحمل لتوفير مساحة؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteSurah(id);
                                              },
                                              child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.cloud_download, color: Colors.grey),
                                    onPressed: () => _downloadSurah(id, surah['fileName']),
                                  ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // شريط التحكم السفلي بالصوت والتشغيل (يظهر عند تشغيل أي سورة)
          if (_currentlyPlayingSurahId != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF002424), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, 
                    blurRadius: 8, 
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'جاري تشغيل سورة: ${QuranData.surahs.firstWhere((element) => element['id'] == _currentlyPlayingSurahId)['name']}',
                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Slider(
                    activeColor: Colors.tealAccent,
                    inactiveColor: Colors.grey,
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white, size: 28),
                        onPressed: () async {
                          await _audioPlayer.stop();
                          setState(() {
                            _currentlyPlayingSurahId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.tealAccent, size: 48),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}