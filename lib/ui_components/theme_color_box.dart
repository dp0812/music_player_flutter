import 'package:flutter/material.dart';

/// Provide the color box consisting of 2 color: primary and highlight. 
class ThemeColorBox extends StatelessWidget {
    final String themeName;
    final Color primaryColor;
    final Color highlightColor;
    final bool isSelected;
    final VoidCallback onTap;

    const ThemeColorBox({
        super.key,
        required this.themeName,
        required this.primaryColor,
        required this.highlightColor,
        required this.isSelected,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: Container(
                margin: const EdgeInsets.all(2),
                decoration: _buildColorSwatchBox(),
                child: Center(
                    child: Text(
                        themeName, // Just the color name.
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                    ),
                ),
            ),
        );
    }

    Decoration _buildColorSwatchBox(){
        return BoxDecoration(
            gradient: LinearGradient(  // Color split accross the diagonal axis. 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor, highlightColor, highlightColor],
                stops: [0, 0.5, 0.5, 1],
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? primaryColor.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
            ),
        );
    }
}