import 'package:flutter/material.dart';
import 'package:music_player/ui_components/title_and_subtitle.dart';
import 'island_base.dart';

/// A custom checkbox list tile which use the same design as the custom list tile. 
class CustomCheckboxListTile extends StatelessWidget {
    /// Typically the album art. 
    final Widget? leading;
    final String title;
    final String? subtitle;
    /// Condition which the tile is condered selected. 
    final bool isSelected;
    final ValueChanged<bool?>? onChanged;
    final Color? selectedColor;
    final Color? unselectedColor;
    final EdgeInsetsGeometry? contentPadding;

    const CustomCheckboxListTile({
        super.key,
        required this.title,
        this.subtitle,
        required this.isSelected,
        this.onChanged,
        this.leading,
        this.selectedColor,
        this.unselectedColor,
        this.contentPadding,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        final Color effectiveSelectedColor = selectedColor ?? colorScheme.onPrimary;
        final Color effectiveUnselectedColor = unselectedColor ?? 
            (theme.listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white);
        
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: GestureDetector(
                onTap: onChanged != null ? () => onChanged!(!isSelected) : null,
                child: IslandBase(
                    child: Container(
                        padding: contentPadding ?? const EdgeInsets.all(12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                if (leading != null) ...[
                                    leading!,
                                    const SizedBox(width: 12),
                                ],
                                
                                TitleAndSubtitle(
                                    title: title, 
                                    subtitle: subtitle ?? "", 
                                    textColor: effectiveUnselectedColor, 
                                    selected: isSelected, 
                                    selectedTextColor: effectiveSelectedColor,
                                ),
                                
                                const SizedBox(width: 12),
                                
                                _CustomCheckbox(
                                    value: isSelected,
                                    onChanged: onChanged,
                                    selectedColor: effectiveSelectedColor,
                                    unselectedColor: effectiveUnselectedColor,
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

/// Provide light selection effect.  
class _CustomCheckbox extends StatelessWidget {
    final bool value;
    final ValueChanged<bool?>? onChanged;
    final Color selectedColor;
    final Color unselectedColor;

    const _CustomCheckbox({
        required this.value,
        required this.onChanged,
        required this.selectedColor,
        required this.unselectedColor,
    });

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onChanged != null ? () => onChanged!(!value) : null,
            child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: value ? selectedColor : unselectedColor,
                        width: 2,
                    ),
                color: value ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: value
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: selectedColor,
                    )
                    : null,
            ),
        );
    }
}