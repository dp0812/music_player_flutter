import 'package:flutter/material.dart';
import '../entities/song.dart';


/// All thing related to the current Song being played - name, progress bar, etc.
class NowPlayingDisplay extends StatelessWidget {
    final Song? currentSong;
    final Duration duration;
    final Duration position;
    final ValueChanged<double> onSeek;

    const NowPlayingDisplay({
        super.key, 
        required this.currentSong,
        required this.duration,
        required this.position,
        required this.onSeek
    });

    /// Format Duration to a readable MM:SS string
    String _formatDuration(Duration d) {
        if (d.inSeconds < 0) return "00:00";
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        final minutes = twoDigits(d.inMinutes.remainder(60));
        final seconds = twoDigits(d.inSeconds.remainder(60));
        return '$minutes:$seconds';
    }

    @override
    Widget build(BuildContext context) {
        // Determine values of progress bar in ms for scrolling -> higher precision than s 
        final totalMilliseconds = duration.inMilliseconds.toDouble();
        final currentMilliseconds = position.inMilliseconds.toDouble();

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    // Song title if applicable. 
                    Text(
                        currentSong?.title ?? "Not Playing Anything",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                    ),
                    // Progress bar
                    Slider(
                        min: 0.0,
                        //if totalMilliseconds was not loading faster enough, render a max value of 1 ms (and not just let the bar die)
                        max: totalMilliseconds > 0 ? totalMilliseconds : 1.0, 
                        // Current value = the current position (in ms)
                        value: currentMilliseconds.clamp(0.0, totalMilliseconds), //clamp force the current position to be VALID, instead of, 1ms > max.
                        // User drag the ball on the progress bar. 
                        onChanged: (newValue) {onSeek(newValue);},
                    ),           
                    // Time Display (Current time / Total time)
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(_formatDuration(position)), // Current position
                            Text(_formatDuration(duration)), // Total duration
                        ],
                    ),
                ],
            ),
        );
    }
}
