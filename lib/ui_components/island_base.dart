import 'package:flutter/material.dart';

/// Solid background for a widget, using the islandColor (onSecondary). 
/// 
/// Remarks: This is a replacement for the [GlassMorph] in list view to reduce the amount of visual noises. 
class IslandBase extends StatelessWidget{
    final Widget child; 
    final BorderRadius borderRadius;

    const IslandBase({
        super.key, 
        required this.child,
        this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    });
    
    @override
    Widget build(BuildContext context) {
        final islandColor = Theme.of(context).colorScheme.onSecondary; 
        return Container(
            decoration:  BoxDecoration(
                color: islandColor,  
                borderRadius: borderRadius,
            ),
            child: child,
        );
    }
}