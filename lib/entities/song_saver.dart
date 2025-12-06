import 'dart:io';

import 'package:music_player/entities/song.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SongSaver {
    static const String _masterFileName = "masterList.txt";
    static String separator = Platform.lineTerminator;
    static File? _masterFile;

    /// Accept a plain playlistName with no file extension. 
    /// Will create a file with this name, replacing space with underscore, and write an empty string to file. 
    static Future<void> savePlaylist({required String playlistName}) async {
        try {
            final playlistFile = await getPlaylistFile(playlistName: playlistName);
            // Write empty string to make sure the file is indeed created. 
            await playlistFile.writeAsString('', mode: FileMode.write);
            print("Saved playlist to: ${playlistFile.path}");
        }catch (e) {
            print("Cannot save playlist due to $e");
        }    
        
    }

    /// Create the file (if it doesn't exist), write the song path on a new line.
    static Future<void> saveSongPath(Song songObject, {String? playlistName}) async {
        try {
            if (playlistName != null) {
                final playlistFile = await getPlaylistFile(playlistName: playlistName);
                await playlistFile.writeAsString(songObject.assetPath+separator, mode: FileMode.append);
                print("Saved path to playlist $playlistName: ${songObject.assetPath}");
            }
            final masterFile = await getMasterFile();            
            await masterFile.writeAsString(songObject.assetPath+separator, mode: FileMode.append);
            print("Successfully saved path: ${songObject.assetPath}");
        } catch (e) {
            print("Error saving song path: $e");
        }
    }

    static Future<List<String>> listPlaylistNames() async {
        try {
            String musicDirPath = await _createMusicDir();
            final directory = Directory(musicDirPath);
            if (!await directory.exists()) return [];
            final entities = await directory.list().toList();
            
            List<String> playlistNames = [];
            for (var entity in entities) {
                if (entity is File) {
                    final fileName = p.basename(entity.path);
                    // Filter for files ending in .txt but NOT the master file
                    if (fileName.endsWith('.txt') && fileName != _masterFileName) {
                        // Remove .txt - 4 last char. 
                        final nameWithoutExtension = fileName.substring(0, fileName.length - 4);
                        // Replace all underscore with space. 
                        playlistNames.add(nameWithoutExtension.replaceAll('_', ' '));
                    }
                }
            }
            return playlistNames;
        } catch (e) {
            print("Error listing playlist file names: $e");
            return [];
        }
    }

    /// Load the file that stored the playlist. If this file does not exists, return an empty list.
    /// The behavior of the method is identical for a playlist that exists, but contain nothing, and a playlist that does not exist.  
    static Future<List<String>> loadSavedPlaylist({required String playlistName}) async {
        List<String> savedPaths =[];
        try {
            File currentPlaylistFile = await getPlaylistFile(playlistName: playlistName);
            if (!(await currentPlaylistFile.exists())) return [];
            savedPaths = await loadSavedSongPaths(songPathFile: currentPlaylistFile);
            return savedPaths;
        } catch (e){
            print("Failed to load playlist: $e");
            return [];
        }

    }

    /// Load all song paths written in the file provided by songPathFile.  <br>
    /// The parameter: accessFileFunction must be either of the following: getMasterFile or getPlaylistFile. <br>
    /// This function handles the await for the parameters its caller provide. 
    static Future<List<String>> loadSavedSongPaths({required File songPathFile}) async {
        try {
            final File currentPathFile = songPathFile; //await getMasterFile()
            if (!await currentPathFile.exists()) {
                print("Master list file not found. Returning empty list.");
                return [];
            }            
            String content = await currentPathFile.readAsString();
            List<String> paths = content.trim().split(separator).where((line) => line.isNotEmpty).toList();
            return paths;
        } catch (e) {
            print("Error loading saved song paths: $e");
            return [];
        }
    }

    /// Overwrites the master list file with a new, cleaned list of paths.
    /// Used for cleanup after removing paths that point to non-existent files.
    static Future<void> rewriteSavedSongPaths(List<String> validPaths, {required File songPathFile}) async {
        try {
            final masterFile = songPathFile;
            final content = validPaths.join(separator) + separator; 
            await masterFile.writeAsString(content, mode: FileMode.write);
            print("Master list file successfully cleaned and rewritten.");
        } catch (e) {
            print("Error rewriting song paths: $e");
        }
    }

    /// Lazily initializes and returns the File object for the master list, 
    /// using a persistent, writable directory (Application Documents).
    static Future<File> getMasterFile() async {
        if (_masterFile == null) {
            String musicDirPath = await _createMusicDir();
            final String fullPath = p.join(musicDirPath, _masterFileName);
            _masterFile = File(fullPath);
            print("Master List file path: $fullPath");
        }
        
        return _masterFile!;
    }

    /// Create a playlist file in the application directory. 
    /// Name of the file is the same as name of the playlist. 
    static Future<File> getPlaylistFile({required String playlistName}) async {
        String musicDirPath = await _createMusicDir();
        // Remove all space, instead use _ This prevent linux system from adding '' to both side. 
        final String formattedName = "${playlistName.replaceAll(' ', '_')}.txt"; 
        final String fullPath = p.join(musicDirPath,formattedName);
        File playlistFile = File(fullPath);
        print("Playlist $playlistName path: $fullPath");
        return playlistFile; 
    }
    
    /// Create application data folder if not exist.
    /// Return a path String to this folder. 
    static Future<String> _createMusicDir() async{
        
        final Directory directory = await getApplicationDocumentsDirectory();
        final String musicDirPath = p.join(directory.path, 'DP_MP3_Player');
        final Directory musicDir = Directory(musicDirPath);

        if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
        }

        return musicDirPath;
    }

}