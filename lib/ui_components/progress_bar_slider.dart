import 'package:flutter/material.dart';

/// Display the progress bar slider.
/// 
/// This widget does not automatically update the UI, thus the caller must provide updating mechanism. 
/// In this case, since the duration is less likely to change compare to the position, 
/// it is advised that the caller wrap this class with [ValueListenableBuilder] for duration then position. This prevent the inner builder from rebuilding unnecessarily. 
///  
/// 
/// An example of usage would be as follow: 
/// ```dart 
/// ValueListenableBuilder(
///     valueListenable: controlsManager.durationNotifier,
///     builder: (context, duration, child) {
///         return ValueListenableBuilder(
///             valueListenable: controlsManager.positionNotifier,
///             builder: (context, position, child) {
///                 return _ProgressBarSlider(duration: duration, position: position, onSeek: onSeek);
///             }
///         );
///     }
/// ),
/// ```
class ProgressBarSlider extends StatelessWidget{
    final Duration duration;
    final Duration position;
    final ValueChanged<double> onSeek;

    const ProgressBarSlider({
        super.key,
        required this.duration, 
        required this.position,
        required this.onSeek,
    });

    @override
    Widget build(BuildContext context) {
        double safeMax = duration.inMilliseconds.toDouble();
        final totalMilliseconds = safeMax;
        final currentMilliseconds = position.inMilliseconds.toDouble().clamp(0.0, totalMilliseconds);
        return Slider(
            min: 0.0,
            // If totalMilliseconds was not loading fast enough, render a max value of 1 ms.
            max: totalMilliseconds > 0 ? totalMilliseconds : 1.0, 
            // Current value = the current position (in ms).
            value: currentMilliseconds,
            // User drag the ball on the progress bar. 
            onChanged: onSeek,
        );
    }
}