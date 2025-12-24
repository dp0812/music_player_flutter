import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../entities/song.dart';
import '../utilities/io_print.dart';

/// This class is responsible for saving to file and loading from file, statically. 
class SongSaver {
    static const String _applicationFolderName = "DP_MP3_Player"; 
    static const String _masterFileName = "masterList.txt";
    /// External accessor to just the name of masterList.txt (no extension)
    static const String masterFileNameExt = "masterList";
    /// For every functions that intends to write anything to file, you MUST use this system separator. DO NOT USE '\n'
    static String separator = Platform.lineTerminator;
    static File? _masterFile;

    SongSaver._();

    /// Will create a file with [playlistName] as name, replacing spaces with underscores. 
    /// Write all path of Song objects in [songs] to this file, separated by the separator (system dependent). 
    /// 
    /// 1. If [songs] is empty, write an empty String to the file. 
    /// 2. [playlistName] MUST NOT have any file extension, and MUST NOT contain any invalid symbols (i). 
    /// 3. [songs] MUST contain only valid songs - with no corrupted paths. 
    /// 4. Remarks: This design is intentional - since we save it here by replacing spaces with underscores, when read with [listPlaylistNames], it is reasonable to do the inverse, that is, replacing underscores with spaces. 
    static Future<void> savePlaylist({required String playlistName, List<Song>? songs}) async {
        try {
            final file = await getPlaylistFile(playlistName: playlistName);
            final paths = songs?.map((song) => song.assetPath).toList() ?? [];
            final content = paths.join(separator) + (paths.isNotEmpty ? separator : '');
            await file.writeAsString(content);
            IO.t("Saved playlist '$playlistName' with ${paths.length} songs");
        } catch (e) {
            IO.e("Error saving playlist: ", error: e);
        }
    }

    /// If caller supply [playlistName], create the [playlistName] file if it doesn't exist and write the assetPath of [songObject] on a new line.
    /// 
    /// If caller does not supply [playlistName], proceed to write this song to the [_masterFileName].
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

    /// Provide a list of [playlistName] currently saved in the application directory. 
    /// 
    /// If only the [_masterFileName] and no other [playlistName].txt is in the application directory, this function return an empty list.
    /// Remarks: When we save the file under some [playlistName] using [savePlaylist], we replace all spaces with underscores, so when we read, we perform the inverse. 
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

    /// Load paths that are available in the playlist [playlistName].
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

    /// Return the File object for the [_masterFileName].
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

    /// Return a playlist file in the application directory, using [playlistName].
    /// 
    /// Name of the file is [playlistName] but replacing all spaces with underscores.
    static Future<File> getPlaylistFile({required String playlistName}) async {
        String musicDirPath = await _createMusicDir();
        // Remove all space, instead use _ 
        final String formattedName = "${playlistName.replaceAll(' ', '_')}.txt"; 
        final String fullPath = p.join(musicDirPath,formattedName);
        File playlistFile = File(fullPath);
        return playlistFile; 
    }
    
    /// Create application data folder if not exist.
    /// 
    /// Return a path String to this folder. 
    static Future<String> _createMusicDir() async{
        
        final Directory directory = await getApplicationDocumentsDirectory();
        final String musicDirPath = p.join(directory.path, _applicationFolderName);
        final Directory musicDir = Directory(musicDirPath);

        if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
        }

        return musicDirPath;
    }

}