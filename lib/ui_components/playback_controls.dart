import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../entities/audio_player_service.dart';

typedef ToggleLoopCallBack = void Function();

/// Provide UI for button controlling the play, stop, resume, loop actions. 
class PlaybackControls extends StatelessWidget {
    final AudioPlayerService audioService;
    final VoidCallback onPlayPauseResume;
    final VoidCallback onStop;
    final ToggleLoopCallBack onToggleLoop;
    final bool isLooping; 
    
    const PlaybackControls({
        super.key,
        required this.audioService,
        required this.onPlayPauseResume,
        required this.onStop,
        required this.onToggleLoop,
        required this.isLooping
    });

    @override
    Widget build(BuildContext context) {
        // Determine the main control button icon 
        final IconData controlIcon = audioService.isPlaying ? Icons.pause : Icons.play_arrow;
        
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    // Loop button. grey out if not click. 
                    IconButton(
                        icon: Icon(Icons.repeat, size: 40, color: isLooping? Colors.blue: Colors.grey),
                        onPressed: onToggleLoop,
                    ),
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
