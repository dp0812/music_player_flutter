import 'package:flutter/material.dart';
import 'package:music_player/entities/audio_player_service.dart';
import 'package:music_player/entities/song_playlist.dart';
import 'package:music_player/pages/playlist_detail_page_state.dart';

/// This page shows user the current Song in the Playlist. 
/// 
/// Functionality wise is very similar to the Home screen.
/// Exceptions include: User can only add song that already existed in the masterList. 
class PlaylistDetailPage extends StatefulWidget {
    final SongsPlaylist playlist;
    final AudioPlayerService audioService;

    const PlaylistDetailPage({
        super.key,
        required this.playlist,
        required this.audioService,
    });

    @override
    State<PlaylistDetailPage> createState() => PlaylistDetailPageState();
}