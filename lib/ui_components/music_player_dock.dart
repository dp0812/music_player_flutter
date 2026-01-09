import 'package:flutter/material.dart';

import 'dock_normal_button.dart';
import 'dock_play_button.dart';
import 'now_playing_display.dart';
import '../entities/audio_player_service.dart';
import '../entities/song_controls_manager.dart';

/// Song title, Progress bar and 5 buttons are placed on a "floating" dock.
/// 
/// Provided two modes: Compact and Expanded, both mode have progress bar, title and control buttons, just with different placement. 
/// 
/// 1. Compact: Title wrapped in marquee effect (if too long), and on the left of the progress bar. All 5 control buttons (i) are below this. 
/// 2. Expanded: Title display in full size, below is the progress bar, and below is the time position + duration. All 5 control buttons (i) are below this. 
/// 3. Control buttons (i): loop, previous, play/pause/resume, next, random (in this exact order). 
/// 
/// Remarks: The rebuild process of the top half and the bottom half are separated. That is: 
/// 1. The top half, which include the title and the progress bar, is rebuilt everytime there is a change with the [currentSongNotifier], [positionNotifier] or the [durationNotifier]. 
/// Specifically, the title is rebuilt when [currentSongNotifier] change, and the progress bar is rebuilt when [durationNotifier] or [positionNotifier] change. 
/// 2. The bottom half, which include all the 5 buttons, is rebuilt when there is a change in the state of a specific button. 
/// For example, if the looping state change, then the loop button is rebuilt.  
class MusicPlayerDock extends StatefulWidget{

    final SongControlsManager controlsManager; 
    final AudioPlayerService audioService;

    /// By default = true. 
    final bool isDisplayProgressBar; 
    /// By default = true. 
    final bool showTitle;
    
    /// Show UI Progress bar (by default) and  
    /// Control buttons loop, previous, play/pause/resume, next, random (in this exact order). 
    const MusicPlayerDock({
        super.key,
        required this.controlsManager, 
        required this.audioService, 
        this.isDisplayProgressBar = true, 
        this.showTitle = true,
    });

    @override
    State<MusicPlayerDock> createState() => MusicPlayerDockState();
}

class MusicPlayerDockState extends State<MusicPlayerDock> {
    /// Mode of top half of the dock. 
    bool _isExpanded = false; 

    /// Song title, Progress bar and 5 buttons are placed on a "floating" dock.
    /// 
    /// The buttons are constrained to look like a box, with the exception of the play/pause/resume button.   
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
                onTap: _toggleExpanded,
                child: PhysicalModel(
                    color: Colors.transparent,
                    elevation: isDark? 6.0 : 4.0,
                    borderRadius: BorderRadius.circular(28.0),
                    shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                    child: Container(
                        decoration: _getDockDecoration(context),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Column(
                            mainAxisSize: MainAxisSize.min, // Don't expand the dock to full screen. 
                            children: [
                                if (widget.isDisplayProgressBar) _buildExpandableIndicator(),
                                
                                // Progress bar => frequent rebuild.
                                if (widget.isDisplayProgressBar)
                                    NowPlayingDisplay(
                                        controlsManager: widget.controlsManager,
                                        onSeek: widget.controlsManager.handleSeek,
                                        isExpanded: _isExpanded,
                                        onToggleExpanded: _toggleExpanded,
                                        pushToDetail: widget.controlsManager.pushToSongDetailPage,  
                                    ),                                   
                                
                                if (widget.isDisplayProgressBar) const SizedBox(height: 5),
                                
                                // Control buttons => less frequent rebuild.
                                _buildControlButtons(context),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }

    /// The five control buttons loop, previous, play/pause/resume, next, random, in this exact order.
    /// 
    /// Each button sit on their own island, with the play button being slightly different. 
    /// Remarks: We only rebuild the loop, random, play button due to them having state (isLooping, isRandom, play pause change). 
    /// The next and previous does not need a change in UI when we click, so they do not need listenable builder. 
    Widget _buildControlButtons(BuildContext context) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                // Loop mode. If isLooping change => rebuild.
                Expanded(
                    child: ValueListenableBuilder<bool>(
                        valueListenable: widget.controlsManager.isLoopingNotifier,
                        builder: (context, isLooping, child) {
                            return DockNormalButton(icon: Icons.repeat, onPressed: widget.controlsManager.toggleLoop, isActive: isLooping,);  
                        },
                    ),
                ),
                
                // Previous song.
                Expanded(child: DockNormalButton(icon: Icons.skip_previous, onPressed: widget.controlsManager.gotoPreviousSong,)),  
                
                // Play song. If isPlaying change => rebuild.
                Expanded(
                    child: ValueListenableBuilder<bool>(
                        valueListenable: widget.controlsManager.isPlayingNotifier,
                        builder: (context, isPlaying, child) {
                            return DockPlayButton(
                                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                                playPauseResume: widget.controlsManager.handlePlayResumePause,   
                            );
                        },
                    ),
                ),
                
                // Next song. 
                Expanded(child: DockNormalButton(icon: Icons.skip_next,onPressed: widget.controlsManager.gotoNextSong,)),  
                
                // Random mode. If isRandom change => rebuild.
                Expanded(
                    child: ValueListenableBuilder<bool>(
                        valueListenable: widget.controlsManager.isRandomNotifier,
                        builder: (context, isRandom, child) {
                            return DockNormalButton(icon: Icons.shuffle, onPressed: widget.controlsManager.toggleRandom, isActive: isRandom,);  
                        },
                    ),
                ),
            ],
        );
    }

    /// Effects for the dock. 
    BoxDecoration _getDockDecoration(BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final baseColor = isDark 
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.surface.withValues(alpha: 0.98);
        
        return BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha:0.15),
                width: 1.0,
            ),
            boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha:isDark ? 0.4 : 0.2),
                    blurRadius: 12.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 4),
                ),
                BoxShadow(
                    color: Colors.black.withValues(alpha:isDark ? 0.3 : 0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                ),
            ],
        );
    }

    /// Just a small rounded line. 
    Widget _buildExpandableIndicator(){
        return Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 0),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
            )
        );
    }

    void _toggleExpanded() {
        setState(() {
            _isExpanded = !_isExpanded;
        });
    }
}
