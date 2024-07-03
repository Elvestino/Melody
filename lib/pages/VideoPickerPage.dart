// // ignore_for_file: file_names

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:video_player/video_player.dart';

// class VideoPickerPage extends StatefulWidget {
//   const VideoPickerPage({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _VideoPickerPageState createState() => _VideoPickerPageState();
// }

// class _VideoPickerPageState extends State<VideoPickerPage> {
//   File? _videoFile;
//   VideoPlayerController? _controller;

//   void _pickVideo() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
//     if (result != null) {
//       File videoFile = File(result.files.single.path!);
//       setState(() {
//         _videoFile = videoFile;
//         _controller = VideoPlayerController.file(videoFile)
//           ..initialize().then((_) {
//             setState(() {});
//             _controller!.play();
//           });
//       });
//     } else {
//       // L'utilisateur a annulé la sélection de la vidéo
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sélectionner une vidéo'),
//       ),
//       body: Center(
//         child: _videoFile != null
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   AspectRatio(
//                     aspectRatio: _controller!.value.aspectRatio,
//                     child: VideoPlayer(_controller!),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       _controller!.pause();
//                       _controller!.seekTo(Duration.zero);
//                       _controller!.play();
//                     },
//                     child: const Text('Rejouer'),
//                   ),
//                 ],
//               )
//             : ElevatedButton(
//                 onPressed: _pickVideo,
//                 child: const Text('Sélectionner une vidéo'),
//               ),
//       ),
//     );
//   }
// }
