import 'package:flutter/material.dart';
import '../entities/audio_player_service.dart';

// ------------------------------------------------
// 4. Extracted UI Component: Playback Controls
// ------------------------------------------------

class PlaybackControls extends StatelessWidget {
    final AudioPlayerService audioService;
    // Callbacks for button actions
    final VoidCallback onPlayPauseResume;
    final VoidCallback onStop;

    const PlaybackControls({
        super.key,
        required this.audioService,
        required this.onPlayPauseResume,
        required this.onStop,
    });

    @override
    Widget build(BuildContext context) {
        // Determine the main control button icon based on the service state
        final IconData controlIcon = 
            audioService.isPlaying 
                ? Icons.pause 
                : Icons.play_arrow;
        
        return BottomAppBar(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                    // Main Play/Pause/Resume Button
                    IconButton(
                        icon: Icon(controlIcon, size: 40),
                        onPressed: onPlayPauseResume, // Executes the parent's logic
                    ),
                    
                    // Stop Button
                    IconButton(
                        icon: const Icon(Icons.stop, size: 40),
                        onPressed: onStop, // Executes the parent's logic
                    ),
                ],
            ),
        );
    }
}
