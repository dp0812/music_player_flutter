import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utilities/io_print.dart';
import 'song_saver.dart';

/// Save and load theme configuration for applicationt theme.
/// 
/// Create a custome config file under the name [_configFileName] in the application directory.
/// Remarks: The idea is so that future theme can be save in some json format, 
/// thus instead of modify the source code, the user can just come in and modify the json. 
class ThemeConfigManager {
    static const String _configFileName = "player.config";
    static const String _themeKey = "dark_theme";
  
    /// Save theme to the config file using json encode. 
    static Future<void> saveTheme(String themeName) async {
        try {
            final configPath = await _appConfigPath;
            final config = {_themeKey: themeName,};
            final file = File(configPath);
            final jsonString = jsonEncode(config);
            await file.writeAsString(jsonString, flush: true);
            
            IO.i('Theme saved to config file: $themeName');
        } catch (e) {
            IO.e("Error saving theme to config file:", error: e);
        }
    }
  
    /// Load theme from the config file.
    static Future<String?> loadTheme() async {
        try {
            final configPath = await _appConfigPath;
            final file = File(configPath);
            if (!await file.exists()) return null; 

            final String jsonString = await file.readAsString();
            final Map<String, dynamic> config = jsonDecode(jsonString);    
            final String? themeName = config[_themeKey]; 
            if (themeName == null) return null; 

            IO.i("Theme loaded from config file: $themeName");
            return themeName;
        } catch (e) {
            IO.e("Error loading theme from config file:", error: e);
        }
        
        return null;
    }

    /// Get the path to the [_configFileName] in application directory.
    /// 
    /// Create the directory if that directory does not exist beforehand.
    /// Remarks: This *could* be extra due to the SongSaver already have a similar method that does the "creation if not exist" 
    /// for the application directory.
    static Future<String> get _appConfigPath async {
        try {
            final directory = await getApplicationDocumentsDirectory();
            final String musicDirPath = p.join(directory.path, SongSaver.applicationFolderName);
            final Directory musicDir = Directory(musicDirPath);
            if (!await musicDir.exists()) {
                await musicDir.create(recursive: true);
            }
            final String configFilePath = p.join(musicDirPath, _configFileName);
            return configFilePath;
        } catch (e) {
            IO.e("Error getting app directory:", error: e);
            rethrow;
        }
    }
}