// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/common/color_extension.dart';
import 'package:test1/pages/FavoritesPage.dart';
import 'package:test1/pages/VideoPlayerHomePage.dart';
import 'MusicPlayerPage.dart';
import 'package:permission_handler/permission_handler.dart';
class MusicPlayerHomePage extends StatefulWidget {
  const MusicPlayerHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MusicPlayerHomePageState createState() => _MusicPlayerHomePageState();
}

class _MusicPlayerHomePageState extends State<MusicPlayerHomePage> with SingleTickerProviderStateMixin {
  List<SongModel> songs = [];
  List<SongModel> recentSongs = [];
  List<SongModel> favoriteSongs = [];
  SharedPreferences? prefs;
  TabController? controller;
  int selectTab = 0;
  String _searchQuery = ''; // Variable pour stocker le texte de recherche
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSongs();
    loadRecentSongs();
    controller = TabController(length: 2, vsync: this);
    controller?.addListener(() {
      setState(() {
        selectTab = controller?.index ?? 0;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> loadSongs() async {
    songs = await fetchSongs();
    setState(() {});
  }

  void _playSong(SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          songList: songs,
          initialIndex: songs.indexOf(song),
        ),
      ),
    );
    addRecentSong(song);
  }

Future<void> _setAsRingtone(SongModel song) async {
  // Vérifiez si la permission de gestion des paramètres est accordée
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }

  if (await Permission.manageExternalStorage.isGranted) {
    try {
      final Uri ringtoneUri = Uri.parse(song.data);
      final intent = AndroidIntent(
        action: 'android.intent.action.RINGTONE_PICKER',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        arguments: {
          'android.intent.extra.ringtone.TITLE': song.title,
          'android.intent.extra.ringtone.EXISTING_URI': ringtoneUri.toString(),
        },
      );
      await intent.launch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la définition de la sonnerie: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permission refusée pour modifier les paramètres')),
    );
  }
}


Future<void> _deleteSong(SongModel song) async {
  bool confirmDelete = await _showDeleteConfirmationDialog();
  if (confirmDelete) {
    try {
      final file = File(song.data);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          songs.remove(song);
          recentSongs.remove(song);
          favoriteSongs.remove(song);
        });
        // ignore: duplicate_ignore
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${song.title} a été supprimé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le fichier ${song.title} n\'existe pas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression de ${song.title}: $e')),
      );
    }
  }
}
Future<void> checkStoragePermissions() async {
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}



Future<bool> _showDeleteConfirmationDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Supprimer la musique'),
        content: const Text('Voulez-vous vraiment supprimer cette musique ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Annuler la suppression
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Confirmer la suppression
            },
            child: const Text('Supprimer'),
          ),
        ],
      );
    },
  ) ?? false;
}

  Future<void> loadRecentSongs() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? recentSongsIds = prefs?.getStringList('recentSongs') ?? [];
    recentSongs = songs.where((song) => recentSongsIds.contains(song.id.toString())).toList();
    setState(() {});
  }

  void addRecentSong(SongModel song) {
    if (!recentSongs.contains(song)) {
      recentSongs.add(song);
      if (recentSongs.length > 10) {
        recentSongs.removeAt(0);
      }
      List<String> recentSongsIds = recentSongs.map((song) => song.id.toString()).toList();
      prefs?.setStringList('recentSongs', recentSongsIds);
    }
  }

  void toggleFavorite(SongModel song) {
    setState(() {
      if (favoriteSongs.contains(song)) {
        favoriteSongs.remove(song);
      } else {
        favoriteSongs.add(song);
      }
    });
  }

  void removeFavorite(SongModel song) {
    setState(() {
      favoriteSongs.remove(song);
    });
  }

  void _filterSongs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.bg,
        title: Text(
          'Melody',
          style: TextStyle(
            color: TColor.focus,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color:  Color.fromARGB(255, 217, 81, 157),),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesPage(
                    favoriteSongs: favoriteSongs,
                    onRemoveFavorite: removeFavorite,
                  ),
                ),
              );
            },
          ),
        ],
        iconTheme: IconThemeData(
          color: TColor.primaryText,
        ),
      ),
      body: IndexedStack(
        index: selectTab,
        children: [
          Column(
            children: [
              Container(
                color: TColor.bg,
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    
                    hintText: 'Rechercher des musiques',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: TColor.unfocused,
                    prefixIcon: const Icon(Icons.search,color: Colors.white,),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterSongs,
                ),
              ),
              Expanded(child: _buildMusicListView()),
            ],
          ),
          const VideoPlayerHomePage(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: TColor.bg,
        elevation: 0,
        child: TabBar(
          controller: controller,
          indicatorColor: Colors.transparent,
          indicatorWeight: 1,
          labelColor: TColor.primary,
          labelStyle: const TextStyle(fontSize: 10),
          unselectedLabelColor: TColor.primaryText28,
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          tabs: [
            Tab(
              text: "Music",
              icon: Image.asset(
                selectTab == 0 ? "assets/img/test.png" : "assets/img/music_no_pressing.png",
                width: 20,
                height: 20,
              ),
            ),
            Tab(
              text: "Video",
              icon: Image.asset(
                selectTab == 1 ? "assets/img/video.png" : "assets/img/video_no_pressing.png",
                width: 20,
                height: 20,
              ),
            ),
          ],
          onTap: (index) {
            setState(() {
              selectTab = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMusicListView() {
    List<SongModel> filteredSongs = songs.where((song) {
      String title = song.title.toLowerCase();
      String artist = song.artist?.toLowerCase() ?? '';
      return title.contains(_searchQuery) || artist.contains(_searchQuery);
    }).toList();

    return Container(
      color: TColor.bg,
      child: ListView(
        children: [
          Text(
            'Musique Lue Récemment',
            style: TextStyle(
              color: TColor.focus,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...recentSongs.map((song) => ListTile(
                leading: Image.asset(
                  'assets/img/test.png',
                  width: 25,
                  height: 25,
                ),
                title: Text(
                  song.title,
                  style: TextStyle(
                    color: TColor.primaryText,
                  ),
                ),
                subtitle: Text(
                  song.artist ?? 'Aucune Musique',
                  style: TextStyle(
                    color: TColor.primaryText,
                  ),
                ),
                onTap: () {
                  _playSong(song);
                  addRecentSong(song);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        favoriteSongs.contains(song) ? Icons.favorite : Icons.favorite_border,
                        color: TColor.primaryText,
                      ),
                      onPressed: () {
                        toggleFavorite(song);
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case 'play':
                            _playSong(song);
                            break;
                          case 'setRingtone':
                            _setAsRingtone(song);
                            break;
                          case 'delete':
                            _deleteSong(song);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'play',
                          child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Lire'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'setRingtone',
                          child: ListTile(
                            leading: Icon(Icons.music_note),
                            title: Text('Définir comme sonnerie'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Supprimer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          Text(
            'Tous',
            style: TextStyle(
              color: TColor.focus,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...filteredSongs.map((song) => ListTile(
                leading: Image.asset(
                  'assets/img/test.png',
                  width: 25,
                  height: 25,
                ),
                title: Text(
                  song.title,
                  style: TextStyle(
                    color: TColor.primaryText,
                  ),
                ),
                subtitle: Text(
                  song.artist ?? 'Aucune Musique',
                  style: TextStyle(
                    color: TColor.primaryText,
                  ),
                ),
                onTap: () {
                  _playSong(song);
                  addRecentSong(song);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        favoriteSongs.contains(song) ? Icons.favorite : Icons.favorite_border,
                        color:  const Color.fromARGB(255, 217, 81, 157),
                      ),
                      onPressed: () {
                        toggleFavorite(song);
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case 'play':
                            _playSong(song);
                            break;
                          case 'setRingtone':
                            _setAsRingtone(song);
                            break;
                          case 'delete':
                            _deleteSong(song);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'play',
                          child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Lire'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'setRingtone',
                          child: ListTile(
                            leading: Icon(Icons.music_note),
                            title: Text('Définir comme sonnerie'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Supprimer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<List<SongModel>> fetchSongs() async {
    final OnAudioQuery audioQuery = OnAudioQuery();
    List<SongModel> songs = await audioQuery.querySongs();
    return songs;
  }
}
