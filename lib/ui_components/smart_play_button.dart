import 'package:flutter/material.dart';

/// Provide play button for the SongDetailPageState
class SmartPlayButton extends StatelessWidget {
    /// Calller should supply [widget.audioService.isPlaying] for this parameter. 
    final bool isAudioPlaying;
    final VoidCallback onPlayPause;
    final Color buttonColor; 

    const SmartPlayButton({
        super.key,
        required this.isAudioPlaying,
        required this.onPlayPause,
        this.buttonColor = Colors.deepPurpleAccent,
    });

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                IconButton(
                    icon: Icon(
                        isAudioPlaying? Icons.pause_circle_filled: Icons.play_circle_filled,
                        size: 80,
                        color: buttonColor,
                    ),
                    onPressed: onPlayPause,
                    tooltip: isAudioPlaying ? "Pause" : "Play",
                ),
            ],
        );
    }
}