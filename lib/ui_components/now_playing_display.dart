import 'package:flutter/material.dart';
import 'package:music_player/utilities/misc_formatter.dart';
import '../entities/song.dart';

/// Display info of Song being play, including: Song title, progress bar and duration.
/// 
/// Does not contain the controller for looping, stopping, next and previous, but the user can adjust the progress bar for the song. 
class NowPlayingDisplay extends StatelessWidget {
    final Song? currentSong;
    final Duration duration;
    final Duration position;
    final ValueChanged<double> onSeek;
    final bool showTitle;
    final Color? activeColor;
    final Color? inactiveColor;
    /// Set to [true] to stop the UI from displaying last [preventDuration] (in ms) of the progress bar. 
    final bool preventLastDuration; 
    /// Default prevention duration is 50 ms. 
    final int preventDuration;

    const NowPlayingDisplay({
        super.key, 
        required this.currentSong,
        required this.duration,
        required this.position,
        required this.onSeek,
        this.showTitle = true,
        this.activeColor,
        this.inactiveColor,
        this.preventLastDuration = false,
        this.preventDuration = 50,
    });

    @override
    Widget build(BuildContext context) {
        // Calculate safe max value if preventing last [preventDuration] ms, used in SongDetailPageState.
        double safeMax = duration.inMilliseconds.toDouble();
        if (preventLastDuration && duration > Duration(milliseconds: preventDuration)) {
            safeMax = (duration - Duration(milliseconds: preventDuration)).inMilliseconds.toDouble();
        }
        // Determine values of progress bar in ms for scrolling -> higher precision than s 
        final totalMilliseconds = safeMax;
        final currentMilliseconds = position.inMilliseconds.toDouble().clamp(0.0, totalMilliseconds);

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    if (showTitle) _buildSongTitle(),
                    if (showTitle) SizedBox(height: 8),
                    _buildProgressBarSlider(context, totalMilliseconds, currentMilliseconds),
                    _buildTimeOnTwoEnd()
                ],
            ),
            );
    }

    Widget _buildSongTitle(){
        return Text(
            currentSong?.title ?? "Not Playing Anything",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
        );
    }

    Widget _buildProgressBarSlider(BuildContext context, double totalMilliseconds, double currentMilliseconds){
        return Slider(
            min: 0.0,
            //if totalMilliseconds was not loading fast enough, render a max value of 1 ms
            max: totalMilliseconds > 0 ? totalMilliseconds : 1.0, 
            // Current value = the current position (in ms)
            value: currentMilliseconds,
            // User drag the ball on the progress bar. 
            onChanged: onSeek,
            activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
            inactiveColor: inactiveColor ?? Theme.of(context).colorScheme.secondary,
        );
    }

    Widget _buildTimeOnTwoEnd(){
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(MiscFormatter.formatDuration(position > duration ? duration : position)), // Current position, at max then use total duration. 
                Text(MiscFormatter.formatDuration(duration)), // Total duration
            ],
        );
    }
}
