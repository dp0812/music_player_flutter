import 'package:flutter/material.dart';
import 'package:music_player/ui_components/now_playing_display.dart';

import '../entities/audio_player_service.dart';
import '../entities/song.dart';

typedef ToggleLoopCallBack = void Function();
typedef ToggleRandomCallBack = void Function();

/// Provided two modes: Compact and Expanded, both mode have progress bar, title and control buttons, just with different placement. 
/// 
/// 1. Compact: Title wrapped in marquee effect (if too long), and on the left of the progress bar. All 5 control buttons (i) are below this. 
/// 2. Expanded: Title display in full size, below is the progress bar, and below is the time position + duration. All 5 control buttons are below this. 
/// 3. Control buttons (i): loop, previous, play/pause/resume, next, random (in this exact order). 
class MusicPlayerDock extends StatefulWidget{
    // Default Progress bar = true. 
    final bool isDisplayProgressBar; 
    // Required. 
    final Song? currentSong;
    final Duration duration;
    final Duration position;
    final ValueChanged<double> onSeek;
    /// By default = true. 
    final bool showTitle;
    /// Set to [true] to stop the UI from displaying last [preventDuration] (in ms) of the progress bar. 
    final bool preventLastDuration; 
    /// Default prevention duration is 50 ms. 
    final int preventDuration;
    
    // Control buttons. 
    final AudioPlayerService audioService;
    final VoidCallback onPlayPauseResume;
    final VoidCallback onStop;
    final VoidCallback onNextSong; 
    final VoidCallback onPreviousSong; 
    final ToggleLoopCallBack onToggleLoop;
    final ToggleRandomCallBack onToggleRandom; 
    final bool isLooping; 
    final bool isRandom;
    
    /// Show UI Progress bar (by default) + 
    /// Control buttons loop, previous, play/pause/resume, next, random (in this exact order). 
    const MusicPlayerDock({
        super.key,
        // Progress bar. 
        this.isDisplayProgressBar = true, 
        required this.currentSong,
        required this.duration,
        required this.position,
        required this.onSeek,
        this.showTitle = true,
        this.preventLastDuration = false,
        this.preventDuration = 50,
        // Control buttons. 
        required this.audioService,
        required this.onPreviousSong,
        required this.onPlayPauseResume,
        required this.onNextSong, 
        required this.onStop,
        required this.onToggleLoop,
        required this.isLooping,
        required this.onToggleRandom, 
        required this.isRandom
    });

    @override
    State<MusicPlayerDock> createState() => MusicPlayerDockState();
}

class MusicPlayerDockState extends State<MusicPlayerDock> {
    /// Mode of top half of the dock. 
    bool _isExpanded = false; 

    // Button size constraints
    static const double _minButtonSize = 48.0;
    static const double _maxButtonSize = 64.0;
    static const double _minMainButtonSize = 50.0;
    static const double _maxMainButtonSize = 68.0;
    // Size ratios
    static const double _buttonToIconRatio = 0.5;  
    static const double _buttonToSpaceRatio = 0.20; 
    static const double _mainButtonToSpaceRatio = 0.25; 
    static const double _mainButtonToIconRatio = 0.6;

    /// Song title, Progress bar and 5 buttons are placed on a "floating" dock.
    /// 
    /// The buttons are constrained to look like a box, with the exception of the play/pause/resume button.   
    @override
    Widget build(BuildContext context) {
        final IconData controlIcon = widget.audioService.isPlaying ? Icons.pause : Icons.play_arrow;
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
                                if (widget.isDisplayProgressBar) _buildProgressBarSlider(),
                                if (widget.isDisplayProgressBar) SizedBox(height: 5),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                        // Loop has isActive.  
                                        Expanded(child: _buildElevatedButton(context,icon: Icons.repeat, onPressed: widget.onToggleLoop, isActive: widget.isLooping)),
                                        Expanded(child: _buildElevatedButton(context,icon: Icons.skip_previous, onPressed: widget.onPreviousSong)),
                                        // Main play pause button. 
                                        Expanded(child: _buildMainPlayPauseResumeButton(context, icon: controlIcon)),
                                        Expanded(child: _buildElevatedButton(context, icon: Icons.skip_next, onPressed: widget.onNextSong)),
                                        // Random also has isActive
                                        Expanded(child: _buildElevatedButton(context, icon: Icons.shuffle, onPressed: widget.onToggleRandom, isActive: widget.isRandom)),
                                    ],
                                ),
                            ],
                        ),
                    ),
                )
            ),
        );
    }

    /// Build the progress bar, song title and timer (if enabled) 
    Widget _buildProgressBarSlider(){
        return NowPlayingDisplay(
            currentSong: widget.currentSong, 
            duration: widget.duration, 
            position: widget.position, 
            onSeek: widget.onSeek,
            isExpanded: _isExpanded,
            onToggleExpanded: _toggleExpanded,
        );
    }

    /// The main button contains more effects than normal button.  
    Widget _buildMainPlayPauseResumeButton(BuildContext context, {required IconData icon}){
        return LayoutBuilder(
            builder: (context, constraints) {

                final availableSpace = constraints.maxWidth;
                double buttonSize = availableSpace * _mainButtonToSpaceRatio; 
                buttonSize = buttonSize.clamp(_minMainButtonSize, _maxMainButtonSize);
                double iconSize = buttonSize * _mainButtonToIconRatio;
                
                return Center(
                    child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                                BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                    blurRadius: 12.0,
                                    offset: const Offset(0, 4),
                                ),
                            ],
                        ),
                        child: IconButton(
                            icon: Icon(icon, size: iconSize),
                            color: Theme.of(context).colorScheme.onPrimary,
                            onPressed: widget.onPlayPauseResume,
                            style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                            ),
                        ),
                    ),
                );
            },
        );

    }

    /// Buttons with their own islands on the dock. 
    Widget _buildElevatedButton(BuildContext context, {required IconData icon, VoidCallback? onPressed, bool isActive = false}) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        // Loop and Random button. 
        final loopActiveColor = Theme.of(context).colorScheme.onPrimary; 
        final loopInactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
        
        final baseButtonBackground = isDark 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4); 

        return LayoutBuilder(
            builder: (context, constraints) {
                // Calculate button size under constrants
                final availableSpace = constraints.maxWidth;             
                double buttonSize = availableSpace * _buttonToSpaceRatio;
                buttonSize = buttonSize.clamp(_minButtonSize, _maxButtonSize);
                double iconSize = buttonSize * _buttonToIconRatio; 
                
                return Center(
                    child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        // Island for each button. 
                        decoration: BoxDecoration(
                            color: baseButtonBackground,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                                if (isDark) BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 2.0,
                                    offset: const Offset(0, 1),
                                ),
                            ],
                        ),
                        // Icon of the button. 
                        child: IconButton(
                            icon: Icon(
                                icon,
                                size: iconSize,
                                color: isActive ? loopActiveColor : loopInactiveColor,
                            ),
                            onPressed: onPressed,
                            style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: EdgeInsets.zero, 
                            ),
                        ),
                    ),
                );
            },
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
