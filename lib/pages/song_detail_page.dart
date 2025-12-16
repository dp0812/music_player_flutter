import 'package:flutter/material.dart';
import 'package:music_player/entities/audio_player_service.dart';
import 'package:music_player/entities/song.dart';
import 'package:music_player/entities/song_controls_manager.dart';
import 'package:music_player/pages/song_detail_page_state.dart';

class SongDetailPage extends StatefulWidget {
    final Song initialSong;
    final SongControlsManager controlsManager;
    final AudioPlayerService audioService;
    final Duration initialPosition; 
    final Duration initialDuration; 

    const SongDetailPage({
        super.key,
        required this.initialSong,
        required this.controlsManager,
        required this.audioService,
        this.initialPosition = Duration.zero,
        this.initialDuration = Duration.zero
    });

    @override
    State<StatefulWidget> createState() => SongDetailPageState();
}