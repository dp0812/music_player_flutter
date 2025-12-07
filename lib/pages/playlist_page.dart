import 'package:flutter/material.dart';
import 'package:music_player/entities/audio_player_service.dart';
import 'package:music_player/pages/playlist_page_state.dart';

/// Container of the page that shows all current playlist.
/// 
/// Actual logic is provided by the playlist_page_state.dart
class PlaylistPage extends StatefulWidget {
    final AudioPlayerService audioService = AudioPlayerService();
    PlaylistPage({super.key});

    @override
    State<PlaylistPage> createState() => PlaylistPageState();
}