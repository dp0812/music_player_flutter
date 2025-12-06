import 'package:flutter/material.dart';
import '../entities/audio_player_service.dart';
import 'song_screen_state.dart';

/// Container - The current homescreen of the application.
/// Logic (handling of functions call is in song_screen_state.dart)  
class SongScreen extends StatefulWidget {
    final AudioPlayerService audioService = AudioPlayerService();

    SongScreen({super.key});
    
    @override
    State<SongScreen> createState() => SongScreenState();
}
