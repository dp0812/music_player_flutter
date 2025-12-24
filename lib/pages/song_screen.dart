import 'package:flutter/material.dart';

import 'song_screen_state.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/audio_player_service.dart';

/// Song Screen contains all songs in the [SongRepository.masterSongPlaylist.playlistName].txt file.
/// 
/// Handling of functions call is in song_screen_state.dart  
class SongScreen extends StatefulWidget {
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;
    final Song? currentSong;
    final bool isLooping;
    final bool isRandom;
    final Duration currentDuration;
    final Duration currentPosition;
    
    const SongScreen({
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
    SongScreenState createState() => SongScreenState();
}
