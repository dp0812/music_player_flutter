import 'package:flutter/material.dart';
import '../entities/theme_config_manager.dart';
import '../utilities/io_print.dart';
import 'dark_themes.dart';

class ThemeProvider extends ChangeNotifier {

    /// Default color. 
    static final String _defaultThemeName = "Hàn Nguyệt"; 
    String _selectedThemeName = _defaultThemeName;
    String get selectedThemeName => _selectedThemeName;
    
    ThemeData get currentTheme => DarkThemes.getThemeByName(_selectedThemeName) ?? DarkThemes.darkGreen;
    Map<String, ThemeData> get availableThemes => DarkThemes.allThemes;
    
    ThemeProvider() {
        _loadTheme();
    }

    /// Load theme from config file. 
    Future<void> _loadTheme() async {
        try {
            final savedTheme = await ThemeConfigManager.loadTheme();
            if (savedTheme != null && DarkThemes.allThemes.containsKey(savedTheme)) {
                _selectedThemeName = savedTheme;
                IO.i('Successfully loaded theme: $savedTheme');
            } else {
                _selectedThemeName = _defaultThemeName;
                IO.i('Using default theme: $_selectedThemeName');
                await ThemeConfigManager.saveTheme(_selectedThemeName);
            }
            
            notifyListeners();
        } catch (e) {
            IO.e("Error in _loadTheme:", error: e);
            _selectedThemeName = _defaultThemeName;
            notifyListeners();
        }
    }
    
    /// If the selected theme is different, notify listeners and save that to the config file. 
    Future<void> changeTheme(String themeName) async {
        if (!DarkThemes.allThemes.containsKey(themeName)) return;
        if (themeName == selectedThemeName) return;

        _selectedThemeName = themeName;
        notifyListeners();
        _saveThemeAsync(themeName);
    }

    /// Save theme to config file. 
    Future<void> _saveThemeAsync(String themeName) async {
        try {
            await ThemeConfigManager.saveTheme(themeName);
            IO.i('Theme saved to config: $themeName');
        } catch (e) {
            IO.e("Error saving theme to config:", error: e);
        }
    }
        
    Color getThemePrimaryColor(String themeName) {
        final theme = DarkThemes.getThemeByName(themeName);
        return theme!.colorScheme.primary;
    }
    
    Color getThemeSurfaceColor(String themeName) {
        final theme = DarkThemes.getThemeByName(themeName);
        return theme!.colorScheme.surface;
    }

    Color getThemeHighlightColor(String themeName){
        final theme = DarkThemes.getThemeByName(themeName);
        return theme!.colorScheme.onPrimary;
    }

    
}