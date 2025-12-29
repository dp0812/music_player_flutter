import 'dart:io';
import '../entities/playlist_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'song_saver.dart';
import '../entities/song_playlist.dart';
import '../entities/song.dart';
import '../utilities/io_print.dart';

/// Holds actual Song objects data. Contain a special master SongsPlaylist named [masterSongPlaylist], and a Map of sub list, named [allSongPlaylists]. 
class SongRepository {
    /// After changing the [allSongPlaylists] map, either value or identity (swap the object), notify the listener with: 
    /// ```dart 
    /// playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
    /// ```
    static final PlaylistNotifier playlistNotifier = PlaylistNotifier();
    /// Store all the Song objects in the supplier directory. Please make reference to this to the full song list. 
    static SongsPlaylist masterSongPlaylist = SongsPlaylist(playlistName: SongSaver.masterFileNameExt);
    /// Each playlist name is a key, connect to the list of songs. 
    static Map<String,SongsPlaylist> allSongPlaylists = {};

    /// Load playlist data in the application directory and populate the map [SongRepository.allSongPlaylists]
    /// 
    /// For every playlists and songs in each playlist, the functions check the [Song.assetPath]. 
    /// If assetPath can be matched with data in the [masterList.txt], a new Song object with that path will be add to the playlist. 
    /// After obtaining a valid list of paths, trigger write back to the storage file. 
    static Future<void> loadPlaylists() async {
        // Clear in-memory collection before loading
        allSongPlaylists.clear(); 
        final List<String> playlistNames = await SongSaver.listPlaylistNames();
        
        for (String name in playlistNames) {
            List<String> paths = await SongSaver.loadSavedPlaylist(playlistName: name);
            SongsPlaylist newPlaylist = SongsPlaylist(playlistName: name);
            int songsAdded = 0;
            int invalidSongs = 0;
            for (String path in paths) {
                // Find the corresponding Song object from the master collection
                int songIndex = masterSongPlaylist.getCurrentPlaylistSongs().indexWhere((s) => s.assetPath == path);
                if (songIndex == -1){ //not found. 
                    invalidSongs++;
                    continue; 
                }  
                Song validSong = masterSongPlaylist.getCurrentPlaylistSongs()[songIndex];
                newPlaylist.addSong(validSong);
                songsAdded++;
            }
            allSongPlaylists[name] = newPlaylist;
            IO.t('Loaded playlist "$name" with $songsAdded songs.');
            // No invalid songs => next playlist. 
            if (invalidSongs == 0 ) continue;   
            // Otherwise rewrite this valid playlist back to the file
            File currentPlaylistFile = await SongSaver.getPlaylistFile(playlistName: name);
            await SongSaver.rewriteSavedSongPaths(newPlaylist.getAllPathsInPlaylist(), songPathFile: currentPlaylistFile);
            IO.w('Spotted $invalidSongs invalid Song. Write back to playlist "$name" completed!');

        }
        playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
    }

    /// Loads the [masterList.txt] in the application directory, and retrieve the [Song.assetPath] stored in that file. 
    /// 
    /// Remove all invalid Paths (Path that cannot be found on the current system) 
    /// and rewrite the [masterList.txt] to contain only valid paths.  
    /// Remove all Song objects containing the invalid paths from the [SongRepository] storage. 
    /// 
    /// Does not update info in the file containing the playlist. Call [loadPlaylists] to do this!
    static Future<void> loadSongs() async {
        masterSongPlaylist.getCurrentPlaylistSongs().clear(); // Clear any previous songs in the list. 
        File currentWorkingMasterFile = await SongSaver.getMasterFile();
        final List<String> savedPaths = await SongSaver.loadSavedSongPaths(songPathFile: currentWorkingMasterFile);
        final List<String> validPaths = [];
        final List<String> invalidPathsForRemoval = [];

        for (String path in savedPaths) {
            // Check file intergrity.
            if (await isSongFileAvailable(path)) { 
                validPaths.add(path); // This path is valid, keep it
                final String fileName = p.basenameWithoutExtension(path); 
                masterSongPlaylist.getCurrentPlaylistSongs().add(await Song.create(title: fileName, assetPath: path));
            } else {
                IO.w("Invalid/Missing file detected, removing path: $path");
                invalidPathsForRemoval.add(path);
            }
        }
        // If length saved != length valid path => rewrite. 
        if (savedPaths.length != validPaths.length ) {
            IO.w("savedPaths.length = ${savedPaths.length} and validPaths.length = ${validPaths.length}");
            await SongSaver.rewriteSavedSongPaths(validPaths, songPathFile: currentWorkingMasterFile);
        }
        // This is NOT redundant. If this check is excluded, the UI will contain invalid songs on the list. 
        for (String invalidPath in invalidPathsForRemoval){
            masterSongPlaylist.getCurrentPlaylistSongs().removeWhere((song) => song.assetPath == invalidPath);
        }
    }

    /// Add a new playlist with [name], replacing all dot(s) and forbidden symbols (i) with empty string.
    /// 
    /// If there exist another playlist with [name], no new playlist is created.  
    /// The newly added playlist will be write to disk.
    /// Remarks: underscore are treated as space when read from disk. Use this with caution.  
    static Future<bool> addPlaylist(String name) async {
        // The following forbidden symbols (i) are strictly NOT allowed, and WILL be replaced with  empty string.  
        // < (less than)
        // > (greater than)
        // : (colon)
        // " (double quote)
        // / (forward slash)
        // \ (backslash) -> this in dart needs to be \\ 
        // | (vertical bar or pipe)
        // ? (question mark)
        // * (asterisk)
        // Remove all invalid symbols - trim again after removing. Example: 'test 03 ? ' => 'test 03' (we save as test_03.txt though)
        final normalizedName = name.trim().replaceAll(RegExp(r'[<>:"/\\|?*.]'), '').trim();
        // Forbid the usage of masterList as a name. 
        if (normalizedName == SongSaver.masterFileNameExt){
            IO.w('"$normalizedName" is a preserved name. Please use other name.');
            return false; 
        }
        // Forbid dupplication. 
        if (allSongPlaylists.containsKey(normalizedName)) {
            IO.t('Playlist "$normalizedName" already exists.');
            return false;
        }
        // Create and store the new playlist
        final newPlaylist = SongsPlaylist(playlistName: normalizedName);
        allSongPlaylists[normalizedName] = newPlaylist;
        IO.t('Created new playlist: "$normalizedName"');
        // Write this playlist to file.
        await SongSaver.savePlaylist(playlistName: normalizedName);
        playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
        return true;
    }

    /// Delete a playlist with [name] and notify all listeners. 
    /// 
    /// This both remove the playlist from [allSongPlaylists] and from the file system.
    /// Only return true when the playlist is successfully remove from BOTH of these storage.   
    static Future<bool> deletePlaylist(String name) async {
        final String normalizedName = name.trim();
        if (allSongPlaylists[normalizedName] == null) {
            IO.d("Playlist name $normalizedName does not exists.");
            return false; 
        }
        
        // Remove this playlist from the Song Repository. 
        allSongPlaylists.remove(normalizedName);
        // Remove this playlist from the FILE system.
        final File currentPlaylistFile = await SongSaver.getPlaylistFile(playlistName: normalizedName);
        if (! (await currentPlaylistFile.exists())) {
            IO.w("File does not exist. Abort deletion.");
            return false; 
        }

        try {
            await currentPlaylistFile.delete();
            IO.t("Delete the following file: ${currentPlaylistFile.path}");
        } catch (e){
            IO.e("Error deleting file.", error: e);
        }

        playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
        return true; 
    }

    /// Add songs to the existing playlist [playlistName] and write back to disk. 
    /// 
    /// Notify all of its listener if any new song is added, otherwise do nothing. 
    static Future<void> addSongsFromCollection({required String playlistName, required List<Song> newSongs}) async {
        if (allSongPlaylists[playlistName] == null) return; 
        if (allSongPlaylists[playlistName]!.addAll(newSongs)) {
            IO.t("New song(s) added.");
            playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
            SongSaver.savePlaylist(playlistName: playlistName, songs: allSongPlaylists[playlistName]!.getCurrentPlaylistSongs());
        }
    }

    /// Add the current song to existing playlist(s) and write back to disk.
    /// 
    /// Notify all of its listener if any new song is added, otherwise do nothing. 
    static Future<void> addSongToSelectedPlaylists({required List<String> playlistNames, required Song newSong}) async {
        if (playlistNames.isEmpty) return; 
        bool changed = false; 
        for (String name in playlistNames){
            if (!allSongPlaylists.containsKey(name)) continue; 
            if (allSongPlaylists[name]!.addSong(newSong)) {
                IO.d("Added ${newSong.title} to playlist $name.");
                SongSaver.savePlaylist(playlistName: name, songs: allSongPlaylists[name]!.getCurrentPlaylistSongs());
                changed = true; 
            }
        }
        if (changed) playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
    }

    /// Prompt user to add songs, using the OS file system (song MUST be .mp3 file). 
    /// 
    /// Currently only call by the SongScreenState, to add to the masterList. 
    static Future<int> addSongsFromUserSelection() async {
        try {
            if (Platform.isAndroid || Platform.isIOS) {
                await Permission.audio.request();
            }
            
            FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple: true, 
                type: FileType.custom,
                allowedExtensions: ['mp3'], // Filter specifically for MP3 files
            );
            // User canceled the picker
            if (result == null) return 0;
            // Otherwise keep track of how many new song added. 
            int songsAdded = 0;
            for (PlatformFile platformFile in result.files) {
                if (platformFile.path == null) continue; // Missing path => skip. 
                final String filePath = platformFile.path!;
                final String fileName = p.basenameWithoutExtension(filePath); 
                final Song newSong = await Song.create(title: fileName, assetPath: filePath);
                if (masterSongPlaylist.getCurrentPlaylistSongs().any((song) => song.assetPath == filePath)){ // Any dupplicate path exits => skip. 
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                // If pass both checks => must be unique. 
                masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
                await SongSaver.saveSongPath(newSong);
                songsAdded++;
            }
            return songsAdded;
        } catch (e) {
            IO.e("Error selecting files: ", error: e); 
            return 0;
        }
    }

    /// Let user pick a directory from the file system, add all .mp3 files to the master list. 
    /// 
    /// This will recursively search the directory AND any other sub directories to get all the files but ONLY .mp3 files will be added. 
    static Future<int> fetchSongsFromUserDirectory() async {
         try {            
            String? result = await FilePicker.platform.getDirectoryPath();
            // User canceled the picker
            if (result == null) return 0;
            // Directory should exist but im a coward. 
            Directory currentDir = Directory(result);
            if (!await currentDir.exists()){
                IO.w("Non-existent directory: $result");
                return 0; 
            }
            // Otherwise keep track of how many new song added. 
            int songsAdded = 0;
            Stream<FileSystemEntity> potentialSongsList = currentDir.list(recursive: true, followLinks: false);
            List<String> mp3PathsList = await _getMP3FilesFromStream(potentialSongsList);
            for (String somePath in mp3PathsList){
                final String fileName = p.basenameWithoutExtension(somePath); 
                final Song newSong = await Song.create(title: fileName, assetPath: somePath);
                if (masterSongPlaylist.getCurrentPlaylistSongs().any((song) => song.assetPath == somePath)){ // Any dupplicate path exits => skip. 
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                // If pass both checks => must be unique. 
                masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
                await SongSaver.saveSongPath(newSong);
                songsAdded++;
                if (songsAdded % 10 == 0) {IO.i("Added $songsAdded song(s) so far...");}
            }
            IO.i("Scanning completed. Total song(s) added: $songsAdded song(s)!");
            return songsAdded;
        } catch (e) {
            IO.e("Error selecting files: ", error: e); 
            return 0;
        }
    }

    /// Helper to filter only paths with .mp3 files. 
    /// 
    /// It could be more efficient to process from stream directly for large directory (explained by some stack overflow answer) but I dislike stream. 
    /// Thus, we will convert them for my own sanity. 
    static Future<List<String>> _getMP3FilesFromStream(Stream<FileSystemEntity> entityStream) async {
        List<String> mp3Paths = [];
        try {
            // This construct of await for is "the" way of processing stream. Link: https://dart.dev/libraries/async/using-streams
            await for (FileSystemEntity entity in entityStream) { 
                try {
                    if (entity is File) {
                        String path = entity.path;
                        if (path.toLowerCase().endsWith('.mp3')) {
                            mp3Paths.add(path);
                        }
                    }
                } catch (e) {
                    IO.w("Skipping inaccessible file: ${entity.path}");
                }
            }
        } catch (e) {
            IO.e("Error processing directory stream: ", error: e);
        }
        
        return mp3Paths;
    }


    /// Remove all instance of Song object in the playlist where its assetPath == [newSong.assetPath].
    /// 
    /// If the [playlistName] matches the masterList, this song will be remove from the masterList (and, will cause cascading changes when reload). 
    static Future<void> deleteSongFromPlaylist({required String playlistName, required Song newSong}) async {
        IO.t("Playlist name = $playlistName");
        IO.t("Song to be delete = ${newSong.assetPath}");
        // Check if user attempt to delete from masterList. 
        if (playlistName == masterSongPlaylist.playlistName){
            IO.w("Song to be delete from masterList = ${newSong.assetPath}");
            // Remove song with same path. 
            masterSongPlaylist.getCurrentPlaylistSongs().removeWhere((s) => s.assetPath == newSong.assetPath);
            masterSongPlaylist.updateSongCount();
            // Write to file. 
            await SongSaver.savePlaylist(playlistName: masterSongPlaylist.playlistName, songs: masterSongPlaylist.getCurrentPlaylistSongs());
            playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists); 
            IO.w("Removed.");
            return; 
        }
        
        // Remove songs from other playlists, as usual. 
        if (allSongPlaylists[playlistName] == null) return;

        // Remove song with same path. 
        allSongPlaylists[playlistName]!.getCurrentPlaylistSongs().removeWhere((s) => s.assetPath == newSong.assetPath);
        allSongPlaylists[playlistName]!.updateSongCount();
        // Write to file. 
        await SongSaver.savePlaylist(playlistName: playlistName, songs: allSongPlaylists[playlistName]!.getCurrentPlaylistSongs());
        playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);  
    }

    /// Returns true if the path provided leads to a valid, existing file. 
    static Future<bool> isSongFileAvailable(String path) async {
        final cleanPath = path.trim();
        return await File(cleanPath).exists();
    }
}