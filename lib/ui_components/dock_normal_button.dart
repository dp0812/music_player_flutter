import 'package:flutter/material.dart';
import 'constraints.dart';

/// Buttons with their own islands on the dock.
/// 
/// This include the following: loop, previous, next, random. 
class DockNormalButton extends StatelessWidget{
    final IconData icon;
    final VoidCallback? onPressed;
    final bool isActive;

    const DockNormalButton({
        super.key, 
        required this.icon, 
        this.onPressed, 
        this.isActive = false
    }); 
  
    /// Buttons with their own islands on the dock.
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final iconActiveColor = theme.colorScheme.onPrimary; 
        final iconInactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.9);
        final baseButtonBackground = theme.colorScheme.onSecondary; 

        return LayoutBuilder(
            builder: (context, constraints) {
                // Calculate button size.
                final availableSpace = constraints.maxWidth;             
                double buttonSize = availableSpace * Constraints.kButtonToSpaceRatio;
                buttonSize = buttonSize.clamp(Constraints.kMinButtonSize, Constraints.kMaxButtonSize);
                double iconSize = buttonSize * Constraints.kButtonToIconRatio; 
                
                return Center(
                    child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        // Island for each button. 
                        decoration: BoxDecoration(
                            color: baseButtonBackground,
                            borderRadius: BorderRadius.circular(Constraints.kBorderRadius),
                        ),
                        // Icon of the button. 
                        child: IconButton(
                            icon: Icon(
                                icon,
                                size: iconSize,
                                color: isActive ? iconActiveColor : iconInactiveColor,
                            ),
                            onPressed: onPressed,
                            // The selection effect when hover over the icon. 
                            style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Constraints.kBorderRadius),
                                ),
                                padding: EdgeInsets.zero, 
                            ),
                        ),
                    ),
                );
            },
        );
    }
}