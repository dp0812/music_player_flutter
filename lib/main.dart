import 'package:flutter/material.dart';
import 'package:music_player/pages/welcome_page.dart';
import 'package:music_player/custom_themes/dark_theme_1.dart';
void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: "Flutter MP3 Player",
			theme: DarkTheme1.greenDark,
			home: WelcomePage(),
		);
	}
}