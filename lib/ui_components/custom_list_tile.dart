import 'package:flutter/material.dart';
import 'glass_morph.dart';

/// Custom list tile that allows a leading image (bounded to be circular), a title + a subtitle (column) and trailing buttons (row).
/// 
/// Use a simple blurry effect for the tile using [GlassMorph] and use SizedBox for spacing between the items. 
/// On selected tile, the following happen: 
/// 1. Use rotating effect for the leading image.
/// 2. Add a moving wave at the end (before the last trailing button)
/// 3. Highlight the border of the tile, as well as the text in the tile. 
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
    /// Transparency level, default to 0.09 
    final double? alpha; 
    // Effect when song is selected and playing. 
    final Decoration? decoration;
    /// Rotating effect.  
    final Widget? leadingOverlay;
    final Color? selectedColor; 

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
        this.alpha = 0.09,
        this.decoration,
        this.leadingOverlay,
        this.selectedColor,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final listTileTheme = theme.listTileTheme;        
        final Color defaultSelectedColor = selectedColor ?? listTileTheme.selectedColor ?? theme.colorScheme.onPrimary;
        final Color textColor = listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white;

        return Padding(
            padding: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: GestureDetector(
                onTap: onTap,
                child: GlassMorph(
                    alpha: alpha,
                    child: _ListTileContent(
                        leading: leading,
                        trailing: trailing,
                        padding: padding,
                        title: title,
                        subtitle: subtitle,
                        textColor: textColor,
                        // Selection effect. 
                        selected: selected,
                        selectedColor: defaultSelectedColor,
                        decoration: decoration,
                        leadingOverlay: leadingOverlay,
                    ),
                ),
            ),
        );
    }
}

/// Display the leading, title + subtitle and, if provided trailing buttons, then add the buttons. 
class _ListTileContent extends StatelessWidget {
    final Widget leading;
    final Widget? trailing;
    final EdgeInsetsGeometry? padding;
    final String title;
    final String subtitle;
    final Color textColor;
    /// Condition of what is considered selected. 
    final bool selected;
    /// Effect on the text of the widget if it is selected. 
    final Color selectedColor;
    /// Effect on the tile itself if it is selected. 
    final Decoration? decoration;
    /// Effect on the leading widget of the tile if it is selected. 
    final Widget? leadingOverlay;

    const _ListTileContent({
        required this.leading,
        required this.trailing,
        required this.padding,
        required this.title,
        required this.subtitle,
        required this.textColor,
        // Selection effect. 
        required this.selected,
        required this.selectedColor,
        this.decoration,
        this.leadingOverlay,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: selected ? decoration : null ,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Stack(
                        alignment: .center, 
                        children: [
                            leading, 
                            if (leadingOverlay != null) leadingOverlay!
                        ],
                    ),                    
                    const SizedBox(width: 12),
                    _TitleAndSubtitle(
                        title: title,
                        subtitle: subtitle,
                        selected: selected,
                        selectedColor: selectedColor,
                        textColor: textColor,
                    ),
                    if (trailing != null) const SizedBox(width: 8),
                    if (trailing != null) trailing!,
                ],
            ),
        );
    }
}

/// Both title and subtile are constrained to a single line (if overflow use ...).
/// 
/// Use the selectedColor for the text of selected item. 
class _TitleAndSubtitle extends StatelessWidget {
    final String title;
    final String subtitle;
    final Color textColor;
    // Selection effect. 
    final bool selected;
    final Color selectedColor;

    const _TitleAndSubtitle({
        required this.title,
        required this.subtitle,
        required this.textColor,
        // Selection effect. 
        required this.selected,
        required this.selectedColor,
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