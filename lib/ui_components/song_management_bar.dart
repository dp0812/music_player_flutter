import 'package:flutter/material.dart';
import 'glass_button.dart';

/// A horizontal song management buttons (support up to 2 buttons) bar that sits above the song list.
/// 
/// Use the [GlassButton] for its button child. 
class SongManagementBar extends StatelessWidget {
    final String actionOneLabel; 
    final String actionTwoLabel; 
    final void Function()? buttonActionOne;
    final void Function()? buttonActionTwo;
    
    const SongManagementBar({
        super.key, 
        this.actionOneLabel = "Action One",
        this.actionTwoLabel = "Action Two",
        this.buttonActionOne, 
        this.buttonActionTwo
    });

    @override
    Widget build(BuildContext context) {
        final themeColor = Theme.of(context).colorScheme;
        
        // If no actions provided, return empty container.
        if (buttonActionOne == null && buttonActionTwo == null) return const SizedBox.shrink();
        
        /// Create an effect that the button(s) are sitting on an island. 
        return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: themeColor.onSecondary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                ),
            ),
            child: Row(
                mainAxisSize: .max,
                mainAxisAlignment: .center,
                children: [
                    if (buttonActionOne != null)
                        GlassButton(
                            onTap: buttonActionOne!,
                            icon: Icons.add,
                            text: actionOneLabel,
                            color: themeColor.onPrimary,
                        ),
                    
                    if (buttonActionOne != null && buttonActionTwo != null) const SizedBox(width: 16),
                    
                    if (buttonActionTwo != null)
                        GlassButton(
                            onTap: buttonActionTwo!,
                            icon: Icons.folder_open,
                            text: actionTwoLabel,
                            color: themeColor.onPrimary,
                        ),
                ],
            ),
        );
    }
}