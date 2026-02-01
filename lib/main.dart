import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'custom_themes/theme_provider.dart';
import 'entities/android_file_system.dart';
import 'entities/album_art_helper.dart';
import 'entities/custom_audio_handler.dart';
import 'entities/audio_player_service.dart';
import 'entities/song_controls_manager.dart';
import 'pages/welcome_page.dart';

/// Global key used in SongControlsManager. 
final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
/// Android Notification system. 
late CustomAudioHandler audioHandler;

Future<void> main() async {
    /// Notification system. 
    WidgetsFlutterBinding.ensureInitialized();
    
    if(Platform.isAndroid) await AndroidFileSystem.requestAndroidPermission();

    final playerService = AudioPlayerService();
    final controlsManager = SongControlsManager(audioService: playerService);
    
    audioHandler = await AudioService.init(
        builder: () => CustomAudioHandler(
            playerService,
            onSkipNext: controlsManager.gotoNextSong,
            onSkipPrev: controlsManager.gotoPreviousSong,
            onSeek: (pos) => controlsManager.handleSeek(pos.inMilliseconds.toDouble()),
            onPlayPauseResume: controlsManager.handlePlayResumePause,
            onStop: controlsManager.stop,
        ),
        config: const AudioServiceConfig(
            androidNotificationChannelName: "DP Music Playback",
            androidNotificationChannelDescription: "MP3 Player - Music playback controls",
            /// androidStopForegroundOnPause MUST be set to false to prevent the "foreground start from background exception". 
            /// There might be other way, but I have yet to find out how. 
            androidStopForegroundOnPause: false, 
        ),
    );
    
    await AlbumArtHelper.cleanUpOldFiles();
    
    /// Actual app run. 
    runApp(MyApp(controlsManager: controlsManager,));
}

class MyApp extends StatelessWidget {

    final SongControlsManager controlsManager; 
	const MyApp({super.key, required this.controlsManager});

	@override
	Widget build(BuildContext context) {
        // Allow the theme preference to be applied to whole app when chosen. 
        return ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
            builder: (context, child) {
                return Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                        return MaterialApp(
                            scaffoldMessengerKey: snackbarKey,
                            navigatorKey: navigatorKey,
                            debugShowCheckedModeBanner: false,
                            title: "MP3 Player",
                            theme: themeProvider.currentTheme,
                            darkTheme: themeProvider.currentTheme,
                            themeMode: ThemeMode.dark,
                            home: WelcomePage(audioService: controlsManager.audioService, controlsManager: controlsManager,),
                        );
                    },
                );
            },
        );
	}
}