import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:music_player/entities/song.dart';
import 'package:music_player/utilities/io_print.dart';

/// This class is responsible for saving to file and loading from file, statically. 
class SongSaver {
    static const String _masterFileName = "masterList.txt";
    /// For every functions that intends to write anything to file, you MUST use this system separator. DO NOT USE '\n'
    static String separator = Platform.lineTerminator;
    static File? _masterFile;

    SongSaver._();

    /// Will create a file with [playlistName] as name, replacing spaces with underscores. 
    /// Write all path of Song objects in [songs] to this file, separated by the separator (system dependent). 
    /// 
    /// If [songs] is empty, write an empty String to the file. 
    /// [playlistName] MUST not have any file extension. 
    /// [songs] MUST contain only valid songs - with no corrupted paths. 
    static Future<void> savePlaylist({required String playlistName, List<Song>? songs}) async {
        try {
            final file = await getPlaylistFile(playlistName: playlistName);
            final paths = songs?.map((song) => song.assetPath).toList() ?? [];
            final content = paths.join(separator) + (paths.isNotEmpty ? separator : ''); //How tf do I not remember this? USE THE FUCKING SEPARATOR.
            await file.writeAsString(content);
            IO.i("Saved playlist '$playlistName' with ${paths.length} songs");
        } catch (e) {
            IO.e("Error saving playlist: ", error: e);
        }
    }

    /// Create the [playlistName] file if it doesn't exist and write the assetPath of [songObject] on a new line.
    /// 
    /// Check for duplications before writing. If [songObject].assetPath already exists in the [playlistName] file, this song is skipped. 
    /// Each assetPath is seperated by the separator (system dependent).  
    static Future<void> saveSongPath(Song songObject, {String? playlistName}) async {
        try {
            if (playlistName != null) {
                final File playlistFile = await getPlaylistFile(playlistName: playlistName);
                List<String> currentSongPaths = await loadSavedSongPaths(songPathFile: playlistFile);
                if (currentSongPaths.every((element) => element != songObject.assetPath)) {
                    await playlistFile.writeAsString(songObject.assetPath+separator, mode: FileMode.append);
                    IO.t("Saved path to playlist $playlistName: ${songObject.assetPath}"); 
                }
            }
            final File masterFile = await getMasterFile();     
            List<String> currentSongPaths = await loadSavedSongPaths(songPathFile: masterFile);
            if (currentSongPaths.every((element) => element != songObject.assetPath)) {
                await masterFile.writeAsString(songObject.assetPath+separator, mode: FileMode.append);
                IO.t("Saved path to masterList.txt: ${songObject.assetPath}");
            }

        } catch (e) {
            IO.e("Error saving song path: ", error: e);
        }
    }

    /// Provide a list of playlist Name currently saved in the application directory. 
    /// 
    /// If only the masterList.txt and no other playlist.txt is in the application directory, this function return an empty list. 
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
            IO.e("Error listing playlist file names: ", error: e);
            return [];
        }
    }

    /// Load paths that are available in the playlist [playlistName] 
    /// 
    /// If this file does not exists, return an empty list.
    /// The behavior of the method is identical for a playlist that exists but contain nothing, and a playlist that does not exist.  
    static Future<List<String>> loadSavedPlaylist({required String playlistName}) async {
        List<String> savedPaths =[];
        try {
            File currentPlaylistFile = await getPlaylistFile(playlistName: playlistName);
            if (!(await currentPlaylistFile.exists())) return [];
            savedPaths = await loadSavedSongPaths(songPathFile: currentPlaylistFile);
            return savedPaths;
        } catch (e){
            IO.e("Failed to load playlist: ", error: e);
            return [];
        }

    }

    /// Load all song paths written in the file provided by [songPathFile]
    /// 
    /// If this file does not exists, return an empty list.
    /// The list of paths returned will NOT contain any end of line separator. 
    static Future<List<String>> loadSavedSongPaths({required File songPathFile}) async {
        try {
            final File currentPathFile = songPathFile;
            if (!await currentPathFile.exists()) {
                IO.w("songPathFile not found. Returning empty list.");
                return [];
            }            
            String content = await currentPathFile.readAsString();
            List<String> paths = content.trim().split(separator).where((line) => line.isNotEmpty).toList();
            return paths;
        } catch (e) {
            IO.e("Error loading saved song paths: ", error: e);
            return [];
        }
    }

    /// Overwrites the current paths in [songPathFile] with a new, cleaned list of [validPaths].
    /// 
    /// Used for cleanup after removing paths that point to non-existent files.
    static Future<void> rewriteSavedSongPaths(List<String> validPaths, {required File songPathFile}) async {
        try {
            final currentWorkingFile = songPathFile;
            final content = validPaths.join(separator) + separator; 
            await currentWorkingFile.writeAsString(content, mode: FileMode.write);
            IO.i("${p.basename(currentWorkingFile.path)} file successfully cleaned and rewritten.");
        } catch (e) {
            IO.e("Error rewriting song paths: ", error: e);
        }
    }

    /// Lazily initializes and returns the File object for the master list, 
    /// using a persistent, writable directory (Application Documents).
    static Future<File> getMasterFile() async {
        if (_masterFile == null) {
            String musicDirPath = await _createMusicDir();
            IO.i("Application directory path: $musicDirPath");
            final String fullPath = p.join(musicDirPath, _masterFileName);
            _masterFile = File(fullPath);
            IO.i("Master List file path: $fullPath");
        }
        
        return _masterFile!;
    }

    /// Return a playlist file in the application directory, using [playlistName]
    /// 
    /// Name of the file is [playlistName] but replacing all spaces with underscores
    static Future<File> getPlaylistFile({required String playlistName}) async {
        String musicDirPath = await _createMusicDir();
        // Remove all space, instead use _ This prevent linux system from adding '' to both side. 
        final String formattedName = "${playlistName.replaceAll(' ', '_')}.txt"; 
        final String fullPath = p.join(musicDirPath,formattedName);
        File playlistFile = File(fullPath);
        // IO.i("Playlist $playlistName path: $fullPath"); // Uncomment this line if you want to see the path - note, this will be overwhelming. 
        return playlistFile; 
    }
    
    /// Create application data folder if not exist.
    /// 
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