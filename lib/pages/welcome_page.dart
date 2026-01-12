import 'package:flutter/material.dart';

import 'welcome_page_state.dart';
import '../entities/song_controls_manager.dart';
import '../entities/audio_player_service.dart';

/// Provides navigation bar and send resources in its state.
/// 
/// These resources will carry on around all different pages of the application.  
class WelcomePage extends StatefulWidget {
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager; 
    const WelcomePage({super.key, required this.audioService, required this.controlsManager});

    @override
    State<WelcomePage> createState() => WelcomePageState();
}