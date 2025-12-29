import 'package:flutter/material.dart';
import 'glass_morph.dart';

/// Custom list tile that allows a leading image (circular), a title + a subtitle (column) and trailing buttons (row).
/// 
/// Use a simple blurry effect for the tile using [GlassMorph] and use SizedBox for spacing between the items. 
class CustomListTile extends StatelessWidget {
    // Required. 
    final Widget leading;
    final String title;
    final String subtitle;
    final void Function() onTap; 
    final bool selected;
    // Optional.
    final Widget? trailing;
    final EdgeInsetsGeometry? padding;
    final EdgeInsetsGeometry? margin;
    /// Transparency level. 
    final double? alpha; 

    const CustomListTile({
        super.key,
        required this.leading,
        required this.title,
        required this.subtitle,
        required this.onTap,
        this.selected = false,
        this.trailing,
        this.padding,
        this.margin,
        this.alpha,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final listTileTheme = theme.listTileTheme;        
        final Color selectedColor = listTileTheme.selectedColor ?? theme.colorScheme.onPrimary;
        final Color textColor = listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white;
        
        return Padding(
            padding: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: GestureDetector(
                onTap: onTap,
                child: GlassMorph(
                    child: _listTileContent(selectedColor,textColor),
                ),
            ),
        );
    }

    /// Display the leading, title + subtitle and, if provided trailing buttons, then add the buttons. 
    Widget _listTileContent(Color selectedColor, Color textColor){
        return Container(
            padding: padding ?? const EdgeInsets.all(12),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    leading,                    
                    const SizedBox(width: 12),
                    _titleAndSubtitle(selectedColor, textColor),
                    if (trailing != null) const SizedBox(width: 8),
                    if (trailing != null) trailing!,
                ],
            ),
        );
    }

    /// Both title and subtile are contrained to a single line (if overflow use ...).
    Widget _titleAndSubtitle(Color selectedColor, Color textColor){
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
                            color: selected ? selectedColor : textColor,
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
                                ? selectedColor.withValues(alpha: 0.7)
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