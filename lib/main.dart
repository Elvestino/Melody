import 'package:flutter/material.dart';
import 'package:test1/pages/MusicPlayerHomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melody',
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MusicPlayerHomePage(),
    );
  }
}
