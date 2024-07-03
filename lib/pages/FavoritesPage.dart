// ignore_for_file: file_names

// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:test1/common/color_extension.dart';

class FavoritesPage extends StatefulWidget {
  final List<SongModel> favoriteSongs;
  final Function(SongModel) onRemoveFavorite; // Callback pour notifier la suppression

  const FavoritesPage({super.key, required this.favoriteSongs, required this.onRemoveFavorite,});

  @override
  // ignore: library_private_types_in_public_api
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liste des Favoris',
          style: TextStyle(
            color: TColor.focus, 
          ),
        ),
        backgroundColor: TColor.bg, 
        iconTheme: IconThemeData(
          color: TColor.primaryText, 
        ),
      ),
      body: Container(
        color: TColor.bg, // Couleur de fond du corps de la page
        child: ListView(
          children: widget.favoriteSongs.map((song) => ListTile(
            leading: Image.asset(
              'assets/img/test.png',
              width: 25,
              height: 25,
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: TColor.primaryText, // Couleur du texte du titre de la chanson
              ),
            ),
            subtitle: Text(
              song.artist ?? 'Aucune Musique',
              style: TextStyle(
                color: TColor.primaryText, // Couleur du texte de l'artiste
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.favorite,
                color: TColor.focus,
              ),
              onPressed: () {
                widget.onRemoveFavorite(song); // Appel du callback pour mettre à jour l'état global
                setState(() {
                  widget.favoriteSongs.remove(song); // Mise à jour locale de la liste des favoris
                });
              },
            ),
            onTap: () {
              // Jouer la chanson ou exécuter une action
            },
          )).toList(),
        ),
      ),
    );
  }
}
