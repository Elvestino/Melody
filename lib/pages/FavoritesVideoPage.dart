// FavoritesVideoPage.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:test1/common/color_extension.dart';
import 'package:test1/pages/VideoPlayerPage.dart';

class FavoritesVideoPage extends StatelessWidget {
  final List<File> favoriteVideos;
 final Function(File) onRemoveFavorite;
  const FavoritesVideoPage({super.key, required this.favoriteVideos, required this.onRemoveFavorite,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.bg,
                iconTheme: IconThemeData(
          color: TColor.primaryText,
        ),
        title: Text(
          'Vidéos Favoris ',
          style: TextStyle(
            color: TColor.focus,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: favoriteVideos.isEmpty
          ? const Center(
              child: Text(
                'Aucune vidéo en favoris',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: favoriteVideos.length,
              itemBuilder: (context, index) {
                final video = favoriteVideos[index];
                return ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.white),
                  title: Text(
                    video.path.split('/').last,
                    style: const TextStyle(color: Colors.white),
                  ),
                  
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(
                          videos: favoriteVideos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
