import 'package:flutter/material.dart';

/// Small, rounded color box to display a certain color for the [current_theme_preview.dart].  
class ColorBall extends StatelessWidget {
    final Color color;
    final String label;

    const ColorBall({
        super.key,
        required this.color,
        required this.label,
    });

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                    ),
                ),
                const SizedBox(height: 6),
                Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
        );
    }
}