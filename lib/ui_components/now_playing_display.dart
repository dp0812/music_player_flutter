import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../entities/song.dart';
import '../utilities/misc_formatter.dart';

/// Display info of Song being played, namely: progress bar, song title (optional, expensive marquee effect) and the position - duration (optional).
/// 
/// This widget is used by the PlaybackControls widget - the bar and the buttons on the same dock. 
/// If [showTitle] = true, position - duration will not be show. Otherwise, position - duration will be display under the progress bar. 
class NowPlayingDisplay extends StatelessWidget {
    final Song? currentSong;
    final Duration duration;
    final Duration position;
    final ValueChanged<double> onSeek;
    final bool showTitle;
    /// Set to [true] to stop the UI from displaying last [preventDuration] (in ms) of the progress bar. 
    final bool preventLastDuration; 
    /// Default prevention duration is 50 ms. 
    final int preventDuration;

    final bool isExpanded; 
    final VoidCallback? onToggleExpanded; 
    /// Clicking on the icon in expanded mode allow the user to go to the Song Detail Page of current Song. 
    final void Function(Song song)? pushToDetail;

    /// This is for the Song Title. 
    static const double boxWidth = 100; 
    static const double boxHeight = 30; 

    const NowPlayingDisplay({
        super.key, 
        required this.currentSong,
        required this.duration,
        required this.position,
        required this.onSeek,
        this.showTitle = true,
        this.preventLastDuration = false,
        this.preventDuration = 50,
        this.isExpanded = false,
        this.onToggleExpanded,
        this.pushToDetail,
    });


    @override
    Widget build(BuildContext context) {
        double safeMax = duration.inMilliseconds.toDouble();
        if (preventLastDuration && duration > Duration(milliseconds: preventDuration)) {
            safeMax = (duration - Duration(milliseconds: preventDuration)).inMilliseconds.toDouble();
        }
        final totalMilliseconds = safeMax;
        final currentMilliseconds = position.inMilliseconds.toDouble().clamp(0.0, totalMilliseconds);

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: GestureDetector(
                onTap: onToggleExpanded,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        isExpanded 
                            ? _buildExpandedView(context, totalMilliseconds, currentMilliseconds)
                            : _buildCompactView(context, totalMilliseconds, currentMilliseconds),
                        // Show the timer for the Song Detail Page State since control is not expandable there.
                        if (onToggleExpanded == null) _buildTimeOnTwoEnd(),
                    ],
                ), 
            ),
        );
    }

    /// Place the Song Title above the progress bar, and the position duration below the progress bar. 
    Widget _buildExpandedView(BuildContext context, double totalMilliseconds, double currentMilliseconds){    
        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Expandable title if callback is provided, else fixed title. 
                (onToggleExpanded != null) ? _expandableTitle() : _notExpandableTitle(),
                // Progress bar.
                _buildProgressBarSlider(context, totalMilliseconds, currentMilliseconds),
                _buildTimeOnTwoEnd(),
            ],
        );
    }

    /// Place the Song title (in Marquee mode if not enough space) to the left of the progress bar. 
    Widget _buildCompactView(BuildContext context, double totalMilliseconds, double currentMilliseconds){
        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (showTitle) _buildSongTitle(),                     
                Expanded(
                    flex: 2,
                    child: _buildProgressBarSlider(context, totalMilliseconds, currentMilliseconds),
                ),
            ],
        );
    }

    /// Fixed line limit = 1. 
    Widget _notExpandableTitle(){
        return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
                currentSong?.title ?? "Not Playing Anything",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
            )
        );
    }

    /// Has higher line limit compare to _notExpandableTitle. 
    Widget _expandableTitle(){
        return GestureDetector(
            onTap: onToggleExpanded,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _titleRow(),
            ),
        );
    }

    Widget _titleRow(){
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                // This is just to even out the other button at the end. 
                Expanded(
                    flex: 1,
                    child: Container(),
                ),
                // Song title. 
                Expanded(
                    flex: 4,
                    child: 
                        Text(
                            currentSong?.title ?? "Not Playing Anything",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,  
                            overflow: TextOverflow.ellipsis, 
                        ),
                ),
                // Button that leads to Song Detail Page State. 
                Expanded(
                    flex: 1, 
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                            child:Icon(Icons.settings),
                            // If provided and currentSong != null, push the user to the Song Detail Page State of the currentSong. 
                            onTap:() {
                                if (currentSong != null && pushToDetail != null) pushToDetail!(currentSong!);
                            }, 
                        ) 
                        
                    ),
                ),
            ],
        );
    }

    /// The marquee function of the Song Title is wrap in a SizedBox to avoid expanding and crashing the entire app. 
    /// 
    /// This function also use the TextPainter to limit the size of the text. 
    Widget _buildSongTitle(){
        String title = currentSong?.title ?? "Not Playing Anything"; 

        // Max width of the song title is 100 pixel. 
        final titlePixelWidth = TextPainter(
            text: TextSpan(
                text: title, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
        )..layout(maxWidth: NowPlayingDisplay.boxWidth);

        // If not enought space, use marquee effect. 
        if (titlePixelWidth.didExceedMaxLines) {
            return SizedBox(  // DO NOT remove this or the marque will crash the app. 
                width: NowPlayingDisplay.boxWidth, 
                height: NowPlayingDisplay.boxHeight, 
                child: Marquee(
                    text: title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 50.0,
                    velocity: 30.0,
                    startPadding: 10.0,
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                ),
            );
        }

        // If there is enough space then just use a normal text title. 
        return SizedBox(
            width: NowPlayingDisplay.boxWidth, 
            height: NowPlayingDisplay.boxHeight, 
            child: Padding( 
                padding: const EdgeInsets.only(top: 4), // Fine tunning for the text to go fuck down. 
                child: Text(
                    title, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                )
            ), 
        );
    }


    /// Progress bar.
    Widget _buildProgressBarSlider(BuildContext context, double totalMilliseconds, double currentMilliseconds){
        return Slider(
            min: 0.0,
            //if totalMilliseconds was not loading fast enough, render a max value of 1 ms
            max: totalMilliseconds > 0 ? totalMilliseconds : 1.0, 
            // Current value = the current position (in ms)
            value: currentMilliseconds,
            // User drag the ball on the progress bar. 
            onChanged: onSeek,
        );
    }

    /// The position and duration, below the progress bar (if applicable).
    Widget _buildTimeOnTwoEnd(){
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(MiscFormatter.formatDuration(position > duration ? duration : position)),
                    Text(MiscFormatter.formatDuration(duration)),
                ],
            ),
        );
    }
}
