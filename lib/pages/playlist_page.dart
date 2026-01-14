import 'package:flutter/material.dart';

import 'playlist_page_state.dart';
import '../entities/audio_player_service.dart';
import '../entities/song_controls_manager.dart';

/// PlaylistPage contains all current playlist(s).
/// 
/// This page does not have any songs display, but the progress bar and the playback controls dock is still here. 
/// Actual logic is provided by the playlist_page_state.dart
class PlaylistPage extends StatefulWidget {
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;
    final void Function(bool isLoading)? onLoadingStateChanged; 
    
    const PlaylistPage({
        super.key,
        required this.audioService,
        required this.controlsManager,
        this.onLoadingStateChanged, 
    });

    @override
    State<PlaylistPage> createState() => PlaylistPageState();
}