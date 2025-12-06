import 'dart:io';

import 'package:music_player/entities/song.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SongSaver {
    static const String _masterFileName = "masterList.txt";
    static String separator = Platform.lineTerminator;
    static File? _masterFile;


    /// Lazily initializes and returns the File object for the master list, 
    /// using a persistent, writable directory (Application Documents).
    static Future<File> _getMasterFile() async {
        if (_masterFile == null) {
            final Directory directory = await getApplicationDocumentsDirectory();
            final String musicDirPath = p.join(directory.path, 'DP_MP3_Player');
            final Directory musicDir = Directory(musicDirPath);
            
            if (!await musicDir.exists()) {
                await musicDir.create(recursive: true);
            }

            final String fullPath = p.join(musicDirPath, _masterFileName);
            _masterFile = File(fullPath);
            print("Master List file path: $fullPath");
        }
        
        return _masterFile!;
    }
    
    /// Create the file (if it doesn't exist), write the song path on a new line.
    static Future<void> saveSongPath(Song songObject, {String? playlistName}) async {
        try {
            if (playlistName != null) {
                print("Playlist saving not yet implemented. Saving to master list.");
            }
            final masterFile = await _getMasterFile();            
            await masterFile.writeAsString(songObject.assetPath+separator, mode: FileMode.append);
            print("Successfully saved path: ${songObject.assetPath}");
        } catch (e) {
            print("Error saving song path: $e");
        }
    }

    static Future<List<String>> loadSavedSongPaths() async {
        try {
            final masterFile = await _getMasterFile();
            if (!await masterFile.exists()) {
                print("Master list file not found. Returning empty list.");
                return [];
            }            
            String content = await masterFile.readAsString();
            List<String> paths = content.trim().split(separator).where((line) => line.isNotEmpty).toList();
            return paths;
        } catch (e) {
            print("Error loading saved song paths: $e");
            return [];
        }
    }

    /// Overwrites the master list file with a new, cleaned list of paths.
    /// Used for cleanup after removing paths that point to non-existent files.
    static Future<void> rewriteSavedSongPaths(List<String> validPaths) async {
        try {
            final masterFile = await _getMasterFile();
            final content = validPaths.join(separator) + separator; 
            await masterFile.writeAsString(content, mode: FileMode.write);
            print("Master list file successfully cleaned and rewritten.");
        } catch (e) {
            print("Error rewriting song paths: $e");
        }
    }

}