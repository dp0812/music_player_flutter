import 'package:flutter/material.dart';
import 'package:music_player/entities/song.dart';
import 'package:music_player/ui_components/now_playing_display.dart';

/// Provide more UI tweaks instead of the normal progress bar
/// 
/// Caller can indicate [activeColor] and [inactiveColor] for the progress bar. 
class SongDetailProgressBar extends StatelessWidget {
    // Display on progress bar. 
    final Song displayedSong;
    final Duration currentDuration;
    final Duration currentPosition;
    final ValueChanged<double> onSeek; // Scrolling the bar. 
    final Color? activeColor;
    final Color? inactiveColor;
    
    // Control flow. 
    final bool isDisplayedSongPlaying;
    final bool songEnded;

    // Optional params. 
    final bool showTitle;
    final Color nowPlayingColorDetail; 
    final Color nowPlayingColorText;
    final Color nowPlayingColorBackground; 
    /// Set to [true] to stop the UI from displaying last [preventDuration] (in ms) of the progress bar. 
    final bool preventLastDuration; 
    /// Default prevention duration is 50 ms. 
    final int preventDuration;

    const SongDetailProgressBar({
        super.key,
        required this.displayedSong,
        required this.currentDuration,
        required this.currentPosition,
        required this.onSeek,
        required this.isDisplayedSongPlaying,
        required this.songEnded,
        required this.activeColor,
        required this.inactiveColor,

        this.showTitle = false,
        this.nowPlayingColorDetail = Colors.green,
        this.nowPlayingColorText = Colors.green,
        this.nowPlayingColorBackground = Colors.lightGreen,
        this.preventLastDuration = true,
        this.preventDuration = 50,
    });

    @override
    Widget build(BuildContext context) {
        final displayPosition = songEnded ? Duration.zero : currentPosition;
        return Column(
            children: [
                // Status indicator (specific to SongDetailPage)
                _buildNowPlayingIndicator(),
                SizedBox(height: 12),
                Stack(
                    children: [
                        // Cut last [preventDuration] ms due to bug problem. 
                        NowPlayingDisplay(
                            currentSong: displayedSong,
                            duration: currentDuration,
                            position: displayPosition,
                            onSeek: onSeek,
                            showTitle: showTitle, 
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            preventLastDuration: preventLastDuration,
                            preventDuration: preventDuration,
                        ),
                        
                        if (songEnded) _buildNotifierWhenSongEnds(),
                    ],
                ),
                
            ],
        );
    }

    Widget _buildNowPlayingIndicator() {
        if (isDisplayedSongPlaying) {
            return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: nowPlayingColorBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: nowPlayingColorDetail),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(Icons.music_note, size: 16, color: nowPlayingColorDetail),
                        SizedBox(width: 6),
                        Text(
                            "Now Playing",
                            style: TextStyle(
                                color: nowPlayingColorText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                            ),
                        ),
                    ],
                ),
            );
        }
        return SizedBox.shrink();
    }

    Widget _buildNotifierWhenSongEnds(){
        return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                        "Song ended - click play or drag to restart",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                        ),
                    ),
                ),
            ),
        );
    }
}