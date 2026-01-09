import 'package:flutter/material.dart';
import 'constraints.dart';

/// Main button of the dock, provide play pause resume based on the current playing status. 
class DockPlayButton extends StatelessWidget{
    final IconData icon; 
    final void Function() playPauseResume; 

    const DockPlayButton({
        super.key, 
        required this.icon, 
        required this.playPauseResume, 
    });
  
    @override
    Widget build(BuildContext context) {
        return LayoutBuilder(
            builder: (context, constraints) {
                // Calculate button size. 
                final availableSpace = constraints.maxWidth;
                double buttonSize = availableSpace * Constraints.kMainButtonToSpaceRatio; 
                buttonSize = buttonSize.clamp(Constraints.kMinMainButtonSize, Constraints.kMaxMainButtonSize);
                double iconSize = buttonSize * Constraints.kMainButtonToIconRatio;
                
                // Display color.
                final baseColor = Theme.of(context).colorScheme.primary;
                final iconHighlightColor = Theme.of(context).colorScheme.onPrimary;  

                return Center(
                    child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                            color: baseColor,
                            shape: BoxShape.circle,
                        ),
                        child: IconButton(
                            icon: Icon(icon, size: iconSize),
                            color: iconHighlightColor,
                            onPressed: playPauseResume,
                            style: IconButton.styleFrom(
                                backgroundColor: baseColor,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                            ),
                        ),
                    ),
                );
            },
        );
    }
}