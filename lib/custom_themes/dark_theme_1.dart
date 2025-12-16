import 'package:flutter/material.dart';
/// Custom dark theme, currently only [greenDark] is good (tested, visually). 
class DarkTheme1 {
    // Static method to create a ThemeData with dark theme preset
    static ThemeData create({
        Color? primaryColor,
        Color? secondaryColor,
        Color? accentColor,
        Color? backgroundColor,
        Color? hightlightColor,
        Brightness brightness = Brightness.dark,
        bool useMaterial3 = true,
    }) {
        return ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor ?? Colors.blue,
                secondary: secondaryColor ?? Colors.green,
                surface: backgroundColor ?? Colors.grey.shade900,
                brightness: brightness,
                onPrimaryContainer: hightlightColor
            ),
            useMaterial3: useMaterial3,
            primaryColor: primaryColor ?? Colors.blue,
            scaffoldBackgroundColor: backgroundColor ?? Colors.grey.shade900,
            appBarTheme: AppBarTheme(
                backgroundColor: primaryColor ?? Colors.blue,
                foregroundColor: Colors.white,
                elevation: 4,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: accentColor ?? Colors.amber,
                foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor ?? Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                ),
                ),
            ),
            inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                ),
            ),
        );
    }

    // Pre-defined theme variations
    static ThemeData get purpleDark => create(
            primaryColor: Colors.purple,
            secondaryColor: Colors.deepPurple,
            accentColor: Colors.amber,
            backgroundColor: Colors.grey.shade900,
        );

    static ThemeData get blueDark => create(
            primaryColor: Colors.blue,
            secondaryColor: Colors.lightBlue,
            accentColor: Colors.amber,
            backgroundColor: Colors.grey.shade900,
        );
    /// To my bestie, who loves dark green dearly. 
    static ThemeData get greenDark => create(
            primaryColor: Colors.teal.shade700,
            secondaryColor: Colors.teal.shade50,
            accentColor: Colors.deepPurpleAccent,
            backgroundColor: Colors.grey.shade900,
            hightlightColor: Colors.deepPurple.shade600,
        );
}