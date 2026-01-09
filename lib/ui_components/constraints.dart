/// Constants use for UI purposes.
/// 
/// Remarks: This is an effort to slowly refactor all the magic number in the UI and make it easier to change once.
/// These are typically the number that I cannot snuck into the themeData and leave as default.  
class Constraints {
    // Button size constraints.
    static const double kMinButtonSize = 48.0;
    static const double kMaxButtonSize = 64.0;
    static const double kMinMainButtonSize = 50.0;
    static const double kMaxMainButtonSize = 68.0;
    // Button ratio constraints.
    static const double kButtonToIconRatio = 0.5;  
    static const double kButtonToSpaceRatio = 0.20; 
    static const double kMainButtonToSpaceRatio = 0.25; 
    static const double kMainButtonToIconRatio = 0.6;
    // Button shape constraints. 
    static const double kBorderRadius = 12; 
    // Marquee title constraints. 
    static const double titleBoxWidth = 100; 
    static const double titleBoxHeight = 30; 
}