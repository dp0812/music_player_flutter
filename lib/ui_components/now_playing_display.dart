import 'package:flutter/material.dart';

import 'marquee_song_title.dart';
import 'progress_bar_slider.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song.dart';
import '../utilities/misc_formatter.dart';

/// Display info of Song being played, namely: progress bar, song title (optional, fancy marquee effect that is not that expensive to rebuild) and the position - duration (optional).
/// 
/// This widget is used by the PlaybackControls widget - the bar and the buttons on the same dock. 
/// If [showTitle] = true, position - duration will not be show. Otherwise, position - duration will be display under the progress bar. 
class NowPlayingDisplay extends StatelessWidget {
    final SongControlsManager controlsManager; 
    final ValueChanged<double> onSeek;
    final bool showTitle;

    final bool isExpanded; 
    final VoidCallback? onToggleExpanded; 
    /// Clicking on the icon in expanded mode allow the user to go to the Song Detail Page of current Song. 
    final void Function(Song song)? pushToDetail;

    /// This is for the Song Title. 
    static const double boxWidth = 100; 
    static const double boxHeight = 30; 

    const NowPlayingDisplay({
        super.key, 
        required this.controlsManager,
        required this.onSeek,
        this.showTitle = true,
        this.isExpanded = false,
        this.onToggleExpanded,
        this.pushToDetail,
    });


    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: GestureDetector(
                onTap: onToggleExpanded,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        isExpanded 
                            ? _buildExpandedView(context)
                            : _buildCompactView(context),
                        // Show the timer for the Song Detail Page State since control is not expandable there.
                        if (onToggleExpanded == null) _buildTimeOnTwoEnd(),
                    ],
                ), 
            ),
        );
    }

    /// Place the Song Title above the progress bar, and the position duration below the progress bar. 
    Widget _buildExpandedView(BuildContext context){    
        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Expandable title if callback is provided, else fixed title. 
                ValueListenableBuilder(
                    valueListenable: controlsManager.currentSongNotifier,
                    builder: (context, newCurrentSong, child) {
                        return (onToggleExpanded != null) ? _expandableTitle(newCurrentSong) : _notExpandableTitle(newCurrentSong);
                    }
                ),
                // Progress bar.
                ValueListenableBuilder(
                    valueListenable: controlsManager.durationNotifier,
                    builder: (context, duration, child) {
                        return ValueListenableBuilder(
                            valueListenable: controlsManager.positionNotifier,
                            builder: (context, position, child) {
                                return ProgressBarSlider(duration: duration, position: position, onSeek: onSeek);
                            }
                        );
                    }
                ),
                _buildTimeOnTwoEnd(),
            ],
        );
    }

    /// Place the Song title (in Marquee mode if not enough space) to the left of the progress bar. 
    Widget _buildCompactView(BuildContext context){
        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (showTitle) ValueListenableBuilder(
                    valueListenable: controlsManager.currentSongNotifier,
                    builder: (context, newCurrentSong, child) {
                        return MarqueeSongTitle(newCurrentSong: newCurrentSong);
                    }
                ),                     
                Expanded(
                    flex: 2,
                    child:
                    ValueListenableBuilder(
                        valueListenable: controlsManager.durationNotifier,
                        builder: (context, duration, child) {
                            return ValueListenableBuilder(
                                valueListenable: controlsManager.positionNotifier,
                                builder: (context, position, child) {
                                    return ProgressBarSlider(duration: duration, position: position, onSeek: onSeek);
                                }
                            );
                        }
                    ),
                ),
            ],
        );
    }

    /// Fixed line limit = 1. 
    Widget _notExpandableTitle(Song? newCurrentSong){
        return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
                newCurrentSong?.title ?? "Not Playing Anything",
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
    Widget _expandableTitle(Song? newCurrentSong){
        return GestureDetector(
            onTap: onToggleExpanded,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _titleRow(newCurrentSong),
            ),
        );
    }

    Widget _titleRow(Song? newCurrentSong){
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
                            newCurrentSong?.title ?? "Not Playing Anything",
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
                            child: const Icon(Icons.settings),
                            // If provided and currentSong != null, push the user to the Song Detail Page State of the currentSong. 
                            onTap:() {
                                if (newCurrentSong != null && pushToDetail != null) pushToDetail!(newCurrentSong);
                            }, 
                        ) 
                        
                    ),
                ),
            ],
        );
    }

    /// The position and duration, below the progress bar (if applicable).
    /// 
    /// Rebuild everytime there is a change in [durationNotifier] or [positionNotifer].
    /// Due to the duration is much less likely to change, it is the outer layer. 
    Widget _buildTimeOnTwoEnd(){
        return ValueListenableBuilder(
            valueListenable: controlsManager.durationNotifier,
            builder: (context, duration, child) {
                return ValueListenableBuilder(
                    valueListenable: controlsManager.positionNotifier,
                    builder: (context, position, child) {
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
                );
            }
        );
    }
}