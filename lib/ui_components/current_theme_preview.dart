import 'package:flutter/material.dart';

import 'color_ball.dart';

/// Provide information of what color is being used for primary, secondary, accent and highlight. 
/// 
/// This is only being used by the [settings_page_state.dart]. 
class CurrentThemePreview extends StatelessWidget {
    const CurrentThemePreview({super.key});

    @override
    Widget build(BuildContext context) {
        final currentTheme = Theme.of(context);

        return Card(
            color: currentTheme.colorScheme.surface,
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            "Active Theme",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.colorScheme.onSurface,
                            ),
                        ),
                        const SizedBox(height: 16),
                        _buildColorRow(currentTheme),
                    ],
                ),
            ),
        );
    }

    Widget _buildColorRow(ThemeData currentTheme){
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                ColorBall(
                    color: currentTheme.colorScheme.primary,
                    label: "Primary",
                ),
                ColorBall(
                    color: currentTheme.colorScheme.secondary,
                    label: "Secondary",
                ),
                ColorBall(
                    color: currentTheme.colorScheme.onPrimary,
                    label: "Highlight",
                ),
            ],
        );
    }
}