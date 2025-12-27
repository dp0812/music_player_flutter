import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_color_box.dart';
import '../custom_themes/theme_provider.dart';

/// Provide a list of boxes, consisting of Primary color and Hightlight color splitted across the diagonal axis.  
class ThemeBoxesList extends StatelessWidget {
    const ThemeBoxesList({super.key});

    @override
    Widget build(BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final currentTheme = Theme.of(context);

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _buildHeader(currentTheme),
                _buildPresetThemeBox(context, themeProvider),
            ],
        );
    }

    /// Simple header with a moon icon. 
    Widget _buildHeader(ThemeData currentTheme){
        return  Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
                children: [
                    Icon(Icons.nightlight_round, color: currentTheme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                        "Preset themes",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.colorScheme.onSurface,
                        ),
                    ),
                ],
            ),
        );
    }

    /// Compact, mimalistic view: plain text name, color splitted along the main diagonal. 
    /// 
    /// After user selected it will have the color around the box.  
    Widget _buildPresetThemeBox(BuildContext context, ThemeProvider themeProvider){
        return  GridView.builder( 
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context), 
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,  
                childAspectRatio: 2.5,
            ),
            itemCount: themeProvider.availableThemes.length,
            itemBuilder: (context, index) {
                final themeName = themeProvider.availableThemes.keys.elementAt(index);
                final primaryColor = themeProvider.getThemePrimaryColor(themeName);
                final highlightColor = themeProvider.getThemeHighlightColor(themeName);
                final isSelected = themeName == themeProvider.selectedThemeName;
                
                return ThemeColorBox(
                    themeName: themeName,
                    primaryColor: primaryColor,
                    highlightColor: highlightColor,
                    isSelected: isSelected,
                    onTap: () => themeProvider.changeTheme(themeName),
                );
            },
        );
    }

    // Helper method to make grid responsive.
    int _getCrossAxisCount(BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth < 400) {
            return 2; 
        } else if (screenWidth < 600) {
            return 3; 
        } else {
            return 4; 
        }
    }
}