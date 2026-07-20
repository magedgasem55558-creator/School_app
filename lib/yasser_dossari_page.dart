import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class YasserDossariQuranPage extends StatefulWidget {
  const YasserDossariQuranPage({Key? key}) : super(key: key);

  @override
  State<YasserDossariQuranPage> createState() => _YasserDossariQuranPageState();
}

class _YasserDossariQuranPageState extends State<YasserDossariQuranPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;

  final List<Map<String, String>> _surahs = [
    {'name': 'الفاتحة', 'url': 'https://server11.mp3quran.net/yasser/001.mp3'},
    {'name': 'البقرة', 'url': 'https://server11.mp3quran.net/yasser/002.mp3'},
    {'name': 'آل عمران', 'url': 'https://server11.mp3quran.net/yasser/003.mp3'},
    {'name': 'يس', 'url': 'https://server11.mp3quran.net/yasser/036.mp3'},
    {'name': 'الرحمن', 'url': 'https://server11.mp3quran.net/yasser/055.mp3'},
    {'name': 'الملك', 'url': 'https://server11.mp3quran.net/yasser/067.mp3'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url, int index) async {
    if (_currentlyPlayingIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingIndex = index;
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم - ياسر الدوسري'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: _surahs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final surah = _surahs[index];
          final isThisPlaying = _currentlyPlayingIndex == index && _isPlaying;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                'سورة ${surah['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('القارئ: ياسر الدوسري'),
              trailing: IconButton(
                icon: Icon(
                  isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.teal,
                  size: 36,
                ),
                onPressed: () => _playAudio(surah['url']!, index),
              ),
            ),
          );
        },
      ),
    );
  }
}
