// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test1/common/color_extension.dart';
import 'package:test1/pages/FavoritesVideoPage.dart';
import 'package:test1/pages/VideoPlayerPage.dart';

class VideoPlayerHomePage extends StatefulWidget {
  const VideoPlayerHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerHomePageState createState() => _VideoPlayerHomePageState();
}

class _VideoPlayerHomePageState extends State<VideoPlayerHomePage> {
  List<File> _videos = [];
  final List<File> _favoriteVideos = [];
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _requestPermissionsAndFetchVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndFetchVideos() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      await _fetchVideos();
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de stockage refusée')),
      );
    }
  }

  Future<void> _fetchVideos() async {
    var result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      List<AssetEntity> videos = await PhotoManager.getAssetPathList(
        type: RequestType.video,
      ).then((List<AssetPathEntity> paths) => paths.first.getAssetListPaged(page: 0, size: 100));

      setState(() {
        _videos = videos.map((video) => File("${video.relativePath!}/${video.title!}")).toList();
      });
    }

    if (_videos.isEmpty) {
      List<File> videos = [];
      List<Directory> directories = await _getVideoDirectories();

      for (var directory in directories) {
        videos.addAll(_searchForVideos(directory));
      }

      setState(() {
        _videos = videos;
      });
    }
  }

  Future<List<Directory>> _getVideoDirectories() async {
    List<Directory> directories = [];

    Directory? externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      directories.add(externalDirectory);
    }

    List<Directory>? externalStorageDirectories = await getExternalStorageDirectories();
    if (externalStorageDirectories != null) {
      directories.addAll(externalStorageDirectories);
    }

    Directory? internalDirectory = await getApplicationDocumentsDirectory();
    if (internalDirectory != null) {
      directories.add(internalDirectory);
    }

    directories.add(Directory('/storage/emulated/0/Download'));
    directories.add(Directory('/storage/emulated/0/DCIM/Camera'));
    directories.add(Directory('/storage/emulated/0/Movies'));
    directories.add(Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Video'));
    directories.add(Directory('/storage/emulated/0/Pictures'));

    return directories;
  }

  List<File> _searchForVideos(Directory directory) {
    List<File> videos = [];
    try {
      directory.listSync(recursive: true, followLinks: false).forEach((item) {
        if (item is File && item.path.endsWith('.mp4')) {
          videos.add(item);
        }
      });
    } catch (e) {
      print("Erreur lors de la lecture du répertoire: $e");
    }
    return videos;
  }

  void _playVideoAtIndex(int index) {
    if (index >= 0 && index < _videos.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            videos: _videos,
            initialIndex: index,
          ),
        ),
      );
    }
  }
  void removeFavorite(File song) {
    setState(() {
      _favoriteVideos.remove(song);
    });
  }


  void toggleFavorite(File video) {
    setState(() {
      if (_favoriteVideos.contains(video)) {
        _favoriteVideos.remove(video);
      } else {
        _favoriteVideos.add(video);
      }
    });
  }

  void _filterVideos(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<File> filteredVideos = _videos.where((video) {
      final videoName = video.path.split('/').last.toLowerCase();
      return videoName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.bg,
        title: Text(
          'Vidéos',
          style: TextStyle(
            color: TColor.focus,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color:  Color.fromARGB(255, 217, 81, 157),),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesVideoPage(favoriteVideos: _favoriteVideos, onRemoveFavorite: removeFavorite,),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVideos,
              decoration: InputDecoration(
                hintText: 'Rechercher des vidéos',
              
                filled: true,
                fillColor: TColor.unfocused,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _filterVideos('');
                          });
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: filteredVideos.isEmpty
          ? const Center(
              child: Text(
                'Aucune vidéo trouvée',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final video = filteredVideos[index];
                return ListTile(
                  leading: const Icon(Icons.videocam, color: Color.fromARGB(255, 217, 81, 157)),
                  title: Text(
                    video.path.split('/').last,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _favoriteVideos.contains(video) ? Icons.favorite : Icons.favorite_border,
                          color: _favoriteVideos.contains(video) ?  const Color.fromARGB(255, 217, 81, 157) :  const Color.fromARGB(255, 217, 81, 157),
                        ),
                        onPressed: () {
                          toggleFavorite(video);
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          switch (value) {
                            case 'play':
                              _playVideoAtIndex(index);
                              break;
                            case 'delete':
                              _deleteVideo(video);
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
                  onTap: () {
                    _playVideoAtIndex(index);
                  },
                );
              },
            ),
    );
  }

  Future<void> _deleteVideo(File video) async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      try {
        await video.delete();
        setState(() {
          _videos.remove(video);
          _favoriteVideos.remove(video);
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${video.path.split('/').last} a été supprimé')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression de ${video.path.split('/').last}')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la vidéo'),
          content: const Text('Voulez-vous vraiment supprimer cette vidéo ?'),
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
}
