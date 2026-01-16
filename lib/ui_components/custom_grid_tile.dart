import 'package:flutter/material.dart';

import 'title_and_subtitle.dart';
import 'island_base.dart';

/// Grid tile on the IslandBase that shows a bigger icon, and hide the rename and delete in the 3 dots.  
/// 
/// [isSelected] is currently not being used. 
class CustomGridTile extends StatelessWidget {
    final Widget leading;
    final String title;
    final String subtitle;
    final void Function() onTap;
    final bool isSelected;
    final Widget? trailing;
    
    const CustomGridTile({
        super.key,
        required this.leading,
        required this.title,
        required this.subtitle,
        required this.onTap,
        this.isSelected = false,
        this.trailing,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
        final Color selectedColor = theme.colorScheme.primary;

        return GestureDetector(
            onTap: onTap,
            child: IslandBase(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            /// The image area that expanded over the island, but not entirely. 
                            Expanded(
                                child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSelected
                                            ? Border.all(color: selectedColor, width: 2)
                                            : null,
                                    ),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: leading, // This is the actual image. 
                                    ),
                                ),
                            ),
                            
                            const SizedBox(height: 12),

                            /// The title, subtitle, and the 3 dots.
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                    TitleAndSubtitle(
                                        title: title, 
                                        subtitle: subtitle, 
                                        textColor: textColor, 
                                        selected: isSelected, 
                                        selectedTextColor: selectedColor
                                    ),
                                    if (trailing != null) trailing!, 
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}