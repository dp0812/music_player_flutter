import 'package:flutter/material.dart';

import 'playlist_detail_page_state.dart';
import '../entities/audio_player_service.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song_playlist.dart';

/// This page shows user the current Song in the Playlist. 
/// 
/// Functionality wise is very similar to the Home screen.
/// Exceptions include: User can only add song that already existed in the masterList. 
class PlaylistDetailPage extends StatefulWidget {
    final SongsPlaylist playlist;
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;
    final Song? currentSong;
    final bool isLooping;
    final bool isRandom;
    final Duration currentDuration;
    final Duration currentPosition;
    
    const PlaylistDetailPage({
        super.key,
        required this.playlist,
        required this.audioService,
        required this.controlsManager,
        required this.currentSong,
        required this.isLooping,
        required this.isRandom,
        required this.currentDuration,
        required this.currentPosition,
    });

    @override
    State<PlaylistDetailPage> createState() => PlaylistDetailPageState();
}