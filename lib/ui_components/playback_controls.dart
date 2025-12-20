import 'package:flutter/material.dart';
import '../entities/audio_player_service.dart';

typedef ToggleLoopCallBack = void Function();
typedef ToggleRandomCallBack = void Function();

/// Provide UI for button controlling the loop, previous, play/pause, next, stop actions, in this exact order.
/// 
/// Rework to include some useless (but some what smoother) UI gimmicks.  
class PlaybackControls extends StatelessWidget {
    final AudioPlayerService audioService;
    final VoidCallback onPlayPauseResume;
    final VoidCallback onStop;
    final VoidCallback onNextSong; 
    final VoidCallback onPreviousSong; 
    final ToggleLoopCallBack onToggleLoop;
    final ToggleRandomCallBack onToggleRandom; 
    final bool isLooping; 
    final bool isRandom;
    
    const PlaybackControls({
        super.key,
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

    /// With 5 buttons is placed on a "floating" dock - Ubuntu Gnome style with a couple extensions.  
    @override
    Widget build(BuildContext context) {
        final IconData controlIcon = audioService.isPlaying ? Icons.pause : Icons.play_arrow;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: PhysicalModel(
                color: Colors.transparent,
                elevation: isDark? 6.0 : 4.0,
                borderRadius: BorderRadius.circular(28.0),
                shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                child: Container(
                    decoration: _getDockDecoration(context),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            // Loop has isActive.  
                            _buildElevatedButton(context,icon: Icons.repeat, onPressed: onToggleLoop, isActive: isLooping),
                            _buildElevatedButton(context,icon: Icons.skip_previous, onPressed: onPreviousSong),
                            // Main play pause button. 
                            Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                        BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.5),
                                            blurRadius: 12.0,
                                            offset: const Offset(0, 4),
                                        ),
                                    ],
                                ),
                                child: IconButton(
                                    icon: Icon(controlIcon, size: 30),
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    onPressed: onPlayPauseResume,
                                    style: IconButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(8.0),
                                    ),
                                ),
                            ),
                            _buildElevatedButton(context, icon: Icons.skip_next, onPressed: onNextSong),
                            // Random also has isActive
                            _buildElevatedButton(context, icon: Icons.shuffle, onPressed: onToggleRandom, isActive: isRandom),
                            // _buildElevatedButton(context, icon: Icons.stop, onPressed: onStop),
                        ],
                    ),
                ),
            )
        );
    }
    
    /// Buttons with their own islands on the dock. 
    Widget _buildElevatedButton(BuildContext context, {required IconData icon, VoidCallback? onPressed, bool isActive = false}) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        // Loop and Randome button. 
        final loopActiveColor = Theme.of(context).colorScheme.onPrimaryContainer; 
        final loopInactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
        
        final baseButtonBackground = isDark 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4); 
        return IconButton(
            icon: Icon(
                icon,
                size: 26,
                color: isActive? loopActiveColor : loopInactiveColor
            ),
            onPressed: onPressed,
            style: IconButton.styleFrom(
                backgroundColor: baseButtonBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.all(10.0),
                // even more shadowww
                shadowColor: isDark ? Colors.black.withValues(alpha:0.3) : null,
                elevation: isDark ? 2.0 : 0.0,
            ),
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

}
