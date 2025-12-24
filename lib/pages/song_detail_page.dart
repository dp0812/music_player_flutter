import 'package:flutter/material.dart';

import 'song_detail_page_state.dart';
import '../entities/audio_player_service.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';

/// Display the album picture of the Song, and access to other metadata. 
/// 
/// This page adds a bit more UI elements to the Song. 
/// Actual logic is provided by the song_detail_page_state.dart
class SongDetailPage extends StatefulWidget {
    final Song initialSong;
    final SongControlsManager controlsManager;
    final AudioPlayerService audioService;
    final Duration initialPosition; 
    final Duration initialDuration; 
    final bool isLooping; 
    final bool isRandom; 

    const SongDetailPage({
        super.key,
        required this.initialSong,
        required this.controlsManager,
        required this.audioService,
        required this.isLooping, 
        required this.isRandom, 
        this.initialPosition = Duration.zero,
        this.initialDuration = Duration.zero
    });

    @override
    State<StatefulWidget> createState() => SongDetailPageState();
}