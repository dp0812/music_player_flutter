import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'custom_themes/theme_provider.dart';
import '../pages/welcome_page.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
        // Allow the theme preference to be applied to whole app when chosen. 
        return ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
            builder: (context, child) {
                return Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                        return MaterialApp(
                            debugShowCheckedModeBanner: false,
                            title: "MP3 Player",
                            theme: themeProvider.currentTheme,
                            darkTheme: themeProvider.currentTheme,
                            themeMode: ThemeMode.dark,
                            home: WelcomePage(),
                        );
                    },
                );
            },
        );
	}
}