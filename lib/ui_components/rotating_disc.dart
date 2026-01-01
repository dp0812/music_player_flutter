import 'package:flutter/material.dart';

/// Rotation effect for the album art supplied to [child] widget, by default, the period of rotation = 10s. 
/// 
/// The rotation will stop if the audio is not playing, and continue (from the point it stops) if audio plays again. 
/// For simplicity, let normal position be the 0 degree position, original starting position of the [child].  
/// 
/// Remarks: If the following hold: 
/// 1. A song stopped (due to it not being in loop and reach the end). 
/// 2. And the widget is visible. 
/// 3. And the progress bar reverted to the begining.
/// 
/// Then the disc will NOT automatically go back to normal position. 
class RotatingDisc extends StatefulWidget {
    /// What to rotate. 
    final Widget child;
    /// Condition to rotate. 
    final bool isPlaying;
    /// The period of 1 full rotation. 
    final Duration duration;
    final Curve curve;

    const RotatingDisc({
        super.key, 
        required this.child,
        required this.isPlaying,
        this.duration = const Duration(seconds: 10),
        this.curve = Curves.linear,  // Constant speed. 
    });

    @override
    RotatingDiscState createState() => RotatingDiscState();
}

/// Rotating logic. 
/// 
/// Remarks: The [SingleTickerProviderStateMixin] provides a clock that runs only when the widget is visible (on the screen). 
/// This clock let Flutter calculate the new value and redraw the rotation. Therefore, the following are established: 
/// 1. Corollary 1: The widget will only rotate when it is BOTH visible AND [isPlaying] == true .
/// 2. Corollary 2: If in paused mode ([isPlaying] == false), the animation stops, but it position is preserve, and will resume from said position if in play mode ([isPlaying] == true) again.  
/// 3. Corollary 3: If the widget is dispose (being removed from the widget tree, perhaps due to switching between main pages - SongDetailPage does not count due to Naviagor.push) 
/// then when it is visible again, the rotation restart entirely - back to the normal position.  
class RotatingDiscState extends State<RotatingDisc> with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    @override
    Widget build(BuildContext context) {
        return RotationTransition(
            // End at 1.0 means a full rotation. 
            turns: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                    parent: _controller,
                    curve: widget.curve,  
                ),
            ),
            child: widget.child,
        );
    }

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
            duration: widget.duration,
            vsync: this, // Use the ticker provide by the mixin. 
        );
        
        if (widget.isPlaying) _controller.repeat();
        
    }

    @override
    void didUpdateWidget(RotatingDisc oldWidget) {
        super.didUpdateWidget(oldWidget);
        
        if (widget.isPlaying != oldWidget.isPlaying) {
             
            if (widget.isPlaying) { 
                _controller.repeat(); // Resume from current position.
            } else {
                _controller.stop(); // Pause at current position. 
            }
        }
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }
}