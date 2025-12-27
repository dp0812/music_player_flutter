import 'package:flutter/widgets.dart';

import '../entities/audio_player_service.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import 'settings_page_state.dart';

/// The setting maintain persistent theme using the shared preferences. 
class SettingsPage extends StatefulWidget{
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;
    final Song? currentSong;
    final bool isLooping;
    final bool isRandom;
    final Duration currentDuration;
    final Duration currentPosition;
    
    const SettingsPage({
        super.key,
        required this.audioService,
        required this.controlsManager,
        required this.currentSong,
        required this.isLooping,
        required this.isRandom,
        required this.currentDuration,
        required this.currentPosition
    });

    @override
    State<StatefulWidget> createState() => SettingsPageState();
}