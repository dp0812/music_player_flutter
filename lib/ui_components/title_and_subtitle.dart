import 'package:flutter/material.dart';

/// Both title and subtile are constrained to a single line (if overflow use ...).
/// 
/// Use the [selectedTextColor] for the text of selected item. 
class TitleAndSubtitle extends StatelessWidget {
    final String title;
    final String subtitle;
    final Color textColor;
    // Selection effect. 
    final bool selected;
    final Color selectedTextColor;

    const TitleAndSubtitle({
        super.key,
        required this.title,
        required this.subtitle,
        required this.textColor,
        // Selection effect. 
        required this.selected,
        required this.selectedTextColor,
    });

    @override
    Widget build(BuildContext context) {
        return Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    // Title. 
                    Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: selected ? selectedTextColor : textColor,
                            overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                    ),
                    
                    const SizedBox(height: 2),
                    // Subtitle. 
                    Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected 
                                ? selectedTextColor.withValues(alpha: 0.7)
                                : textColor.withValues(alpha: 0.6),
                            overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                    ),
                ],
            ),
        );
    }
}