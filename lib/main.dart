import 'package:flutter/material.dart';
import 'song_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Flutter MP3 Player',
			theme: ThemeData(
				primarySwatch: Colors.blue,
			),
			//Set SongScreen as the home page
			home: SongScreen(),
		);
	}
}