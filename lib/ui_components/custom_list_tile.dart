import 'package:flutter/material.dart';
import 'island_base.dart';
import 'title_and_subtitle.dart';

/// Custom list tile that allows a leading image (bounded to be circular), a title + a subtitle (column) and trailing buttons (row).
/// 
/// Use a simple blurry effect for the tile using [IslandBase] and use SizedBox for spacing between the items. 
/// On selected tile, the following happen: 
/// 1. Use rotating effect for the leading image.
/// 2. Add a moving wave at the end (before the last trailing button)
/// 3. Highlight the border of the tile, as well as the text in the tile. 
class CustomListTile extends StatelessWidget {
    /// The album art created with [AlbumArt]. 
    final Widget leading;
    final String title;
    final String subtitle;
    /// For song list this is play selected song. For playlist list this is push to Playlist Detail Page.  
    final void Function() onTap; 

    /// Condition of what is considered selected to apply [leadingOverlay] and [selectedTileEffect] and [selectedTextColor].
    final bool isSelected;
    /// Some buttons, or some spinKit effects, or both, attached to the end of the tile.
    final Widget? trailing;
    /// Rotating effect.  
    final Widget? leadingOverlay;
    final Decoration? selectedTileEffect;
    final Color? selectedTextColor; 

    const CustomListTile({
        super.key,
        required this.leading,
        required this.title,
        required this.subtitle,
        required this.onTap,
        this.isSelected = false,
        this.trailing,
        this.selectedTileEffect,
        this.leadingOverlay,
        this.selectedTextColor,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final listTileTheme = theme.listTileTheme;        
        final Color defaultSelectedColor = selectedTextColor ?? listTileTheme.selectedColor ?? theme.colorScheme.onPrimary;
        final Color textColor = listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white;

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: GestureDetector(
                onTap: onTap,
                child: IslandBase(
                    child: _ListTileContent(
                        leading: leading,
                        trailing: trailing,
                        title: title,
                        subtitle: subtitle,
                        textColor: textColor,
                        // Selection effect. 
                        selected: isSelected,
                        selectedTextColor: defaultSelectedColor,
                        selectedTileEffect: selectedTileEffect,
                        leadingOverlay: leadingOverlay,
                    ),
                ),
            ),
        );
    }
}

/// Display the leading, title + subtitle and, if provided trailing widget, then add the widget. 
class _ListTileContent extends StatelessWidget {
    final Widget leading;
    final Widget? trailing;
    final String title;
    final String subtitle;
    final Color textColor;
    /// Condition of what is considered selected. 
    final bool selected;
    /// Effect on the text of the widget if it is selected. 
    final Color selectedTextColor;
    /// Effect on the tile itself if it is selected. 
    final Decoration? selectedTileEffect;
    /// Effect on the leading widget of the tile if it is selected. 
    final Widget? leadingOverlay;

    const _ListTileContent({
        required this.leading,
        required this.trailing,
        required this.title,
        required this.subtitle,
        required this.textColor,
        // Selection effect. 
        required this.selected,
        required this.selectedTextColor,
        this.selectedTileEffect,
        this.leadingOverlay,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(12),  
            decoration: selected ? selectedTileEffect : null ,
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
                    TitleAndSubtitle(
                        title: title,
                        subtitle: subtitle,
                        selected: selected,
                        selectedTextColor: selectedTextColor,
                        textColor: textColor,
                    ),
                    if (trailing != null) const SizedBox(width: 8),
                    if (trailing != null) trailing!,
                ],
            ),
        );
    }
}