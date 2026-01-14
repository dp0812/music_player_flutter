import 'package:flutter/material.dart';

import 'song_screen_state.dart';
import '../entities/song_controls_manager.dart';
import '../entities/audio_player_service.dart';

/// Song Screen contains all songs in the [SongRepository.masterSongPlaylist.playlistName].txt file.
/// 
/// Handling of functions call is in song_screen_state.dart  
class SongScreen extends StatefulWidget {
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;
    final void Function(bool isLoading)? onLoadingStateChanged;
    
    const SongScreen({
        super.key,
        required this.audioService,
        required this.controlsManager,
        this.onLoadingStateChanged, 
    });
    
    @override
    SongScreenState createState() => SongScreenState();
}
