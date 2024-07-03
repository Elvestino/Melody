// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class MusicPlayerPage extends StatefulWidget {
  final List<SongModel> songList;
  final int initialIndex;

  const MusicPlayerPage({super.key, required this.songList, required this.initialIndex});

  @override
  // ignore: library_private_types_in_public_api
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _audioPlayer;
  late List<SongModel> _songList;
  late int _currentIndex;
  bool _isLooping = false;
  bool _isRepeating = false;
  StreamSubscription<Duration?>? _positionSubscription;
  Duration? _duration;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _songList = widget.songList;

    // Trier la liste de chansons par titre
    _songList.sort((a, b) => a.title.compareTo(b.title));

    // Trouver l'index de la chanson initiale après le tri
    _currentIndex = _songList.indexWhere((song) => song.id == widget.songList[widget.initialIndex].id);

    _loadSong(_currentIndex);

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      setState(() {
        if (_duration != null && position != null) {
          _sliderValue = position.inMilliseconds / _duration!.inMilliseconds * 100;
        }
      });
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isLooping) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else {
          _playNext();
        }
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });
  }

  Future<void> _loadSong(int index) async {
    if (index >= 0 && index < _songList.length) {
      final song = _songList[index];
      final mediaItem = MediaItem(
        id: song.uri!, // URI de la chanson
        album: song.album ?? 'Unknown Album', // Album de la chanson
        title: song.title, // Titre de la chanson
        artist: song.artist ?? 'Unknown Artist', // Artiste de la chanson
        artUri: Uri.parse('https://example.com/image.jpg'), // URL de l'image de l'album (changez cela pour correspondre à vos données)
      );

      await _audioPlayer.setAudioSource(AudioSource.uri(
        Uri.parse(song.uri!),
        tag: mediaItem,
      ));
      _audioPlayer.play();
    }
  }

  void _playNext() {
    if (_currentIndex < _songList.length - 1) {
      _currentIndex++;
      _loadSong(_currentIndex);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadSong(_currentIndex);
    }
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeating = !_isRepeating;
      _audioPlayer.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
    });
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Joué maintenant',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, 
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                    customWidths: CustomSliderWidths(
                      trackWidth: 2,
                      progressBarWidth: 4,
                      shadowWidth: 6,
                    ),
                    customColors: CustomSliderColors(
                      dotColor: const Color(0xffFFB1B2),
                      trackColor: const Color(0xffffffff).withOpacity(0.3),
                      progressBarColors: [
                        const Color.fromARGB(255, 195, 91, 209),
                        const Color(0xffE9585A),
                      ],
                      shadowColor: const Color(0xffFFB1B2),
                      shadowMaxOpacity: 0.05,
                    ),
                    infoProperties: InfoProperties(
                      topLabelStyle: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      topLabelText: 'Elapsed',
                      bottomLabelStyle: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      bottomLabelText: 'time',
                      mainLabelStyle: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 50.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    startAngle: 270,
                    angleRange: 360,
                    size: media.width * 0.8,
                  ),
                  min: 0,
                  max: 100,
                  initialValue: _sliderValue,
                  onChange: (double value) {
                    setState(() {
                      _sliderValue = value;
                      _audioPlayer.seek(
                        Duration(milliseconds: (_duration!.inMilliseconds * (value / 100)).toInt()),
                      );
                    });
                  },
                  onChangeStart: (double startValue) {},
                  onChangeEnd: (double endValue) {},
                ),
                Positioned(
                  child: Image.asset(
                    'assets/img/elvestino.png',
                    width: media.width * 0.7,
                    height: media.width * 0.7,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _songList[_currentIndex].title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              _songList[_currentIndex].artist ?? 'Aucune Musique',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _playPrevious,
                  iconSize: 48,
                  color: Colors.white,
                ),
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing ?? false;
                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 48.0,
                        height: 48.0,
                        child: const CircularProgressIndicator(),
                      );
                    } else if (playing) {
                      return IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: _audioPlayer.pause,
                        iconSize: 48,
                        color: Colors.white,
                      );
                    } else {
                      return IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: _audioPlayer.play,
                        iconSize: 48,
                        color: Colors.white,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _playNext,
                  iconSize: 48,
                  color: Colors.white,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRepeating ? Icons.repeat_one : Icons.repeat),
                  onPressed: _toggleRepeat,
                  iconSize: 48,
                  color: _isRepeating ? const Color.fromARGB(255, 195, 91, 209) : Colors.white,
                ),
                IconButton(
                  icon: Icon(_isLooping ? Icons.loop : Icons.loop_outlined),
                  onPressed: _toggleLoop,
                  iconSize: 48,
                  color: _isLooping ? const Color.fromARGB(255, 195, 91, 209) : Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
