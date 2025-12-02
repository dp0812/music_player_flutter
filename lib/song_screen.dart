import 'package:flutter/material.dart';
import 'entities/audio_player_service.dart';
import 'song_screen_state.dart';

// ------------------------------------------------
// 1. The Main Screen (Container for State)
// ------------------------------------------------

class SongScreen extends StatefulWidget {
    final AudioPlayerService audioService = AudioPlayerService();
    
    @override
    State<SongScreen> createState() => SongScreenState();
}







