import 'package:flutter/material.dart';

/// Add a blur layer and some white to the tile. 
class GlassMorph extends StatelessWidget{
    final double blur; 
    final double? alpha; 
    final Widget child; 
    final BorderRadius borderRadius;

    const GlassMorph({
        super.key, 
        this.blur = 0.0, 
        this.alpha = 0.05, 
        required this.child,
        this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    });
    
    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: alpha),
                borderRadius: borderRadius,
                border: Border.all(width: 1.0, color: Colors.white.withValues(alpha:0.1)),
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                    ),
                ],
            ),
            child: child,
        );
    }
}