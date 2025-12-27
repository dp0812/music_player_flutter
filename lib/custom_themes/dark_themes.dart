import 'package:flutter/material.dart';

/// Custom preset dark theme. 
/// 
/// The following list serves as a guidance of the name: 
/// 1. primary : primaryColor
/// 2. secondary : secondaryColor
/// 3. surface : backgroundColor
/// 4. onPrimary : highlightColor
/// Remarks: Of the current 5, Thanh Tiêu is the greenDark theme from before. 
class DarkThemes {
    /// To my bestie, who... well she knows what this color is about. 
    static ThemeData get darkGreen => _createDarkTheme(
            primaryColor: Colors.teal.shade800,
            secondaryColor: Colors.teal.shade50,
            backgroundColor: Colors.grey.shade900,
            highlightColor: Colors.deepPurple.shade600,
            name: "Thanh Tiêu",
        );

    /// To my dear friend, the name of this color is a translation of your name. 
    static ThemeData get darkBlue => _createDarkTheme(
            primaryColor: Colors.blue.shade100,
            secondaryColor: Colors.grey.shade50,
            backgroundColor: Colors.grey.shade900,
            highlightColor: Colors.amber.shade600,
            name: "Bình Minh",
        );

    /// To my bestie, who... well again she knows what this color is about. 
    static ThemeData get darkRed => _createDarkTheme(
            primaryColor: Color(0xFFB0BEC5),  
            secondaryColor: Colors.red.shade50,
            backgroundColor: Colors.grey.shade900,
            highlightColor:  Color(0xFFB71C1C),  
            name: "Xích Ngọc",
        );

    /// Inspiration from one of the frequent activities with my friend. 
    static ThemeData get darkGrey => _createDarkTheme(
            primaryColor: Colors.grey.shade700,
            secondaryColor: Colors.grey.shade300,
            backgroundColor: Colors.grey.shade900,
            highlightColor: Colors.cyan.shade600,
            name: "Hàn Nguyệt",
        );

    /// Get all available dark themes.
    static Map<String, ThemeData> get allThemes => {
            "Thanh Tiêu": darkGreen,
            "Bình Minh": darkBlue,
            "Xích Ngọc": darkRed,
            "Hàn Nguyệt": darkGrey,
        };

    /// Get theme by name.
    static ThemeData? getThemeByName(String name) => allThemes[name];

    /// This is the blueprints for all the widgets in the app right now. 
    /// 
    /// Include preset for the following widgets: 
    /// 1. Bar: appBar, navigationBar,  
    /// 2. Buttons: floatingActionButton, elevatedButton, textButton, slider, dialog,
    /// 3. Container (not the container class): scaffold, card, listTile,
    /// 4. Icons: icon, progress indicator,
    static ThemeData _createDarkTheme({
        required Color primaryColor,
        required Color secondaryColor,
        required Color backgroundColor,
        required Color highlightColor,
        required String name,
        bool useMaterial3 = true,
    }) {
        return ThemeData(
            brightness: Brightness.dark,
            useMaterial3: useMaterial3,
            colorScheme: ColorScheme.dark(
                primary: primaryColor,
                secondary: secondaryColor,
                surface: backgroundColor,
                onPrimary: highlightColor,
                onSecondary: Colors.black,
                onSurface: Colors.grey.shade300, 
            ),
            navigationBarTheme: NavigationBarThemeData(
                indicatorColor: primaryColor, // Color to highlight the destination on the bottom Navigation Bar. 
            ),  
            scaffoldBackgroundColor: backgroundColor,
            appBarTheme: AppBarTheme(
                backgroundColor: primaryColor, // Colors.transparent could also be nice to hide the bar. 
                foregroundColor: highlightColor, // Colors.white is always nice for dark theme based text. 
                elevation: 0,
                centerTitle: true,
                scrolledUnderElevation: 4,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: backgroundColor,
                foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: highlightColor, // Colors.white is always nice for dark theme based text. 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
            ),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: secondaryColor),
            ),
            cardTheme: CardThemeData(
                color: backgroundColor,
                elevation: 4, // Depth feeling for the card in settings. 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),  // Rounded corners. 
            ),
            listTileTheme: ListTileThemeData(
                textColor: secondaryColor,
                iconColor: secondaryColor,
                tileColor: Colors.grey.shade900,
                selectedColor: highlightColor, // Highlight the text instead. 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),),
            ),
            iconTheme: IconThemeData(color: secondaryColor),
            sliderTheme: SliderThemeData(  // Progress bar color shall now be define here. 
                activeTrackColor: primaryColor,
                thumbColor: primaryColor,
                inactiveTrackColor: secondaryColor,
            ),
            progressIndicatorTheme: ProgressIndicatorThemeData(
                color: primaryColor,
            ),
            dialogTheme: DialogThemeData(backgroundColor: backgroundColor),
        );
    }
}