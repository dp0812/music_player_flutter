import 'dart:io';
import 'dart:collection';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'android_file_system.dart';
import 'master_list_notifier.dart';
import 'playlist_notifier.dart';
import 'song_saver.dart';
import 'song_playlist.dart';
import 'song.dart';
import '../utilities/io_print.dart';

/// Holds actual [Song] data. Contain a special master [SongsPlaylist] named [masterSongPlaylist], and a Map of sub list, named [allSongPlaylists]. 
/// 
/// Remarks: About the term "invalid"/ "invalid song" being used in this file, there are 2 definitions: 
/// 1. In [loadSongs]: an invalid song is a song which invoking [isSongFileAvailable] returns false.
///     - Corollary 1: the negation is considered valid (sounds redundant, but there is a need to clarify this). 
/// 2. In [loadPlaylists] and [loadPlaylist] (note that the first is plural, and the second is singular), an invalid song is a song that its assetPath cannot be found in [SongSaver.masterFileNameExt].
///     - Corollary 2: if the assetPath of a song can be found in [SongSaver.masterFileNameExt] BUT cannot be located on the file system, it is a valid song. 
///  
/// Therefore, the defintion of "valid song" depends on the context (haha). 
/// Thus, in definition 2, If we do not want to reload the entire [masterSongPlaylist], 
/// there is a need to add a check for whether a song is on the file system first, then check if it is in [SongSaver.masterFileNameExt]. 
class SongRepository {
    /// After changing the [allSongPlaylists] map, either value or identity (swap the object), notify the listener with: 
    /// ```dart 
    /// playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
    /// ```
    static final PlaylistNotifier playlistNotifier = PlaylistNotifier();
    /// After changing [masterSongPlaylist], either value or identity, notify the listner with: 
    /// ```dart 
    /// masterListNotifier.setMasterListAndNotifyListeners(masterSongPlaylist);
    /// ```
    static final MasterListNotifier masterListNotifier = MasterListNotifier();
    /// Store all the Song objects in the supplier directory. Please make reference to this to the full song list. 
    static SongsPlaylist masterSongPlaylist = SongsPlaylist(playlistName: SongSaver.masterFileNameExt);
    /// Each playlist name is a key, connect to a [SongsPlaylist] which you can call [SongsPlaylist.getCurrentPlaylistSongs] to acquire the list of Songs. 
    static Map<String,SongsPlaylist> allSongPlaylists = {};
    /// Class must be used statically. 
    SongRepository._();

    /// Load playlist data in the application directory and populate the map [SongRepository.allSongPlaylists], removing all invalid songs. 
    /// 
    /// Trigger write back to file if there are invalid songs, or some files no longer exist.
    static Future<void> loadPlaylists() async {
        // Clear in-memory collection before loading
        allSongPlaylists.clear(); 
        final List<String> playlistNames = await SongSaver.listPlaylistNames();
        
        for (String name in playlistNames) {
            List<String> paths = await SongSaver.loadSavedPlaylist(playlistName: name);
            SongsPlaylist newPlaylist = SongsPlaylist(playlistName: name);

            /// This operation ensure that path(s) from paths is actually on the file system. 
            Set<String> pathsToRemove = {}; 
            bool isOnFileSystem = true; 
            for (String path in paths){
                if (await isSongFileAvailable(path)) continue;
                pathsToRemove.add(path);
                isOnFileSystem = false; 
            }
            paths.removeWhere((somePath) => pathsToRemove.contains(somePath));

            final List<Song> validSongs = commonValidSongs(paths);
            newPlaylist.replaceSongs(validSongs); 
            int songsAdded = validSongs.length; 
            int invalidSongs = paths.length - songsAdded; 

            allSongPlaylists[name] = newPlaylist;
            IO.t('Loaded playlist "$name" with $songsAdded songs.');
            // No invalid songs and all files exist => next playlist. 
            if (invalidSongs == 0 && isOnFileSystem) continue;   
            // Otherwise rewrite this valid playlist back to the file.
            File currentPlaylistFile = await SongSaver.getPlaylistFile(playlistName: name);
            await SongSaver.rewriteSavedSongPaths(newPlaylist.getAllPathsInPlaylist(), songPathFile: currentPlaylistFile);
            IO.w('Spotted $invalidSongs invalid Song and isOnFileSystem = $isOnFileSystem. Write back to playlist "$name" completed!');

        }
        playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists);
    }

    /// Load a single playlist, specify by the [playlistName] from [allSongPlaylists] and remove all invalid songs. 
    /// 
    /// Trigger write back to file if there are invalid songs, or some files no longer exist. 
    static Future<void> loadPlaylist({required String playlistName}) async {
        if(!allSongPlaylists.containsKey(playlistName)) return; 

        List<String> paths = await SongSaver.loadSavedPlaylist(playlistName: playlistName);

        /// This operation ensure that path(s) from paths is actually on the file system. 
        Set<String> pathsToRemove = {}; 
        bool isOnFileSystem = true; 
        for (String path in paths){
            if (await isSongFileAvailable(path)) continue;
            pathsToRemove.add(path);
            isOnFileSystem = false; 
        }
        paths.removeWhere((somePath) => pathsToRemove.contains(somePath));

        SongsPlaylist newPlaylist = SongsPlaylist(playlistName: playlistName);

        final List<Song> validSongs = commonValidSongs(paths);
        newPlaylist.replaceSongs(validSongs); 
        int songsAdded = validSongs.length; 
        int invalidSongs = paths.length - songsAdded; 

        allSongPlaylists[playlistName] = newPlaylist;
        IO.t('Loaded playlist "$playlistName" with $songsAdded songs.');
        
        // No invalid songs and all files exist => notify then return. 
        if (invalidSongs == 0 && isOnFileSystem) {
            playlistNotifier.updatePlaylist(playlistName, newPlaylist);
            return; 
        }   
        
        // Otherwise rewrite this valid playlist back to the file. 
        File currentPlaylistFile = await SongSaver.getPlaylistFile(playlistName: playlistName);
        await SongSaver.rewriteSavedSongPaths(newPlaylist.getAllPathsInPlaylist(), songPathFile: currentPlaylistFile);
        IO.w('Spotted $invalidSongs invalid Song and isOnFileSystem = $isOnFileSystem. Write back to playlist "$playlistName" completed!');
        
        playlistNotifier.updatePlaylist(playlistName, newPlaylist);
        return; 
    }

    /// Loads the [masterList.txt] in the application directory, and retrieve the [Song.assetPath] stored in that file. 
    /// 
    /// Remove all invalid Paths (Path that cannot be found on the current system) 
    /// and rewrite the [masterList.txt] to contain only valid paths.  
    /// Remove all Song objects containing the invalid paths from the [SongRepository] storage. 
    /// 
    /// Finally, notify listener with [setMasterListAndNotifyListeners].
    /// 
    /// Does not update info in the file containing the playlist. Call [loadPlaylists] or [loadPlaylist] to do this!
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
        // Notify UI to rebuild. 
        masterListNotifier.setMasterListAndNotifyListeners(masterSongPlaylist);
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

    /// Rename a playlist with name [oldName] to [newName], replacing all dot(s) and forbidden symbols (i) with empty string.
    /// 
    /// 1. If there exist another playlist with [newName], rename will fail.  
    /// 2. If the following is false, then rename will fail.
    /// ```dart 
    /// allSongPlaylists.containsKey(oldName) 
    /// ```
    /// 3. The newly renamed playlist will be write to disk, and the old one will be remove from [allSongPlaylists].
    /// 4. Remarks: Underscore are treated as space when read from disk. Use this with caution.
    static Future<bool> renamePlaylist(String oldName, String newName) async {
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
        final normalizedName = newName.trim().replaceAll(RegExp(r'[<>:"/\\|?*.]'), '').trim();
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
        // Check existence of old playlist. 
        if (!allSongPlaylists.containsKey(oldName)){
            IO.w("Can not find old playlist with name $oldName");
            return false; 
        }

        // Create and store the new playlist, with the songs from old playlist. 
        final newPlaylist = SongsPlaylist(playlistName: normalizedName, songLists: allSongPlaylists[oldName]!.getCurrentPlaylistSongs());
        // Remove the old playlist from map. 
        allSongPlaylists.remove(oldName);
        // Add the new playlist to map. 
        allSongPlaylists[normalizedName] = newPlaylist;
        IO.t('Created new playlist: "$normalizedName"');
        // Write this playlist to file.
        await SongSaver.renamePlaylist(currentPlaylistName: oldName ,newPlaylistName: normalizedName);
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
    /// Before returning (not throwing exception), notify listener with [setMasterListAndNotifyListeners].
    static Future<int> addSongsFromUserSelection() async {
        try {
            // This is mandatory for both picking and scanning on Android.
            if (Platform.isAndroid){
                await AndroidFileSystem.requestAndroidPermission();
            }

            FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple: true, 
                type: FileType.custom,
                allowedExtensions: ['mp3'], // Filter specifically for MP3 files.
            );
            // User canceled the picker.
            if (result == null) return 0;
            // Otherwise keep track of how many new song added. 
            int songsAdded = 0;
            for (PlatformFile platformFile in result.files) {
                if (platformFile.path == null) continue; // Missing path => skip. 
                final String filePath = platformFile.path!;
                final String fileName = p.basenameWithoutExtension(filePath); 
                final Song newSong = await Song.create(title: fileName, assetPath: filePath);
                if (masterSongPlaylist.getCurrentPlaylistSongs().any((song) => newSong.isEqual(song))){ // Any dupplicate song exits => skip. 
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                // If pass both checks => must be unique. 
                masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
                await SongSaver.saveSongPath(newSong);
                songsAdded++;
            }
            // Notify UI to rebuild. 
            masterListNotifier.setMasterListAndNotifyListeners(masterSongPlaylist);
            return songsAdded;
        } catch (e) {
            IO.e("Error selecting files: ", error: e); 
            return 0;
        }
    }

    /// Let user pick a directory from the file system, add all .mp3 files to the master list. 
    /// 
    /// This will recursively search the directory AND any other sub directories to get all the files but ONLY .mp3 files will be added. 
    /// Before returning (not throwing exception), notify listener with [setMasterListAndNotifyListeners].
    static Future<int> fetchSongsFromUserDirectory() async {
        try {
            // This is mandatory for both picking and scanning on Android.
            if (Platform.isAndroid){
                await AndroidFileSystem.requestAndroidPermission();
            }

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
            List<String> mp3PathsList = await getMP3FilesFromStream(potentialSongsList);
            for (String somePath in mp3PathsList){
                final String fileName = p.basenameWithoutExtension(somePath); 
                final Song newSong = await Song.create(title: fileName, assetPath: somePath);
                if (masterSongPlaylist.getCurrentPlaylistSongs().any((song) => newSong.isEqual(song))){ // Any dupplicate song exits => skip. 
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                // If pass both checks => must be unique. 
                masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
                await SongSaver.saveSongPath(newSong);
                songsAdded++;
                if (songsAdded % 10 == 0) IO.i("Added $songsAdded song(s) so far...");
            }
            IO.i("Scanning completed. Total song(s) added: $songsAdded song(s)!");
            // Notify UI to rebuild.
            masterListNotifier.setMasterListAndNotifyListeners(masterSongPlaylist);
            return songsAdded;
        } catch (e) {
            IO.e("Error selecting files: ", error: e); 
            return 0;
        }
    }

    /// Scan 1st the music directory, then the download directory (fallback).
    /// 
    /// This is currently not used (as a button) in the app, but have been tested. 
    /// I intend for this to be a part of the pre-fetch folder in the setting. 
    /// If added song is not 0, notify listener with [setMasterListAndNotifyListeners].
    static Future<int> autoScanFolders() async {
        /// For Android, we need a different approach due to some strange permission problem. 
        if (Platform.isAndroid) {
            int songNum = await AndroidFileSystem.scanAndroidMusicDirectory();
            if (songNum != 0) masterListNotifier.setMasterListAndNotifyListeners(masterSongPlaylist);
            return songNum; 
        }
        return -1; 
    }

    /// Helper to filter only paths with .mp3 files. 
    /// 
    /// It could be more efficient to process from stream directly for large directory (explained by some stack overflow answer) but I dislike stream. 
    /// Thus, we will convert them for my own sanity. 
    static Future<List<String>> getMP3FilesFromStream(Stream<FileSystemEntity> entityStream) async {
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
            // Remove songs that are equals.
            masterSongPlaylist.getCurrentPlaylistSongs().removeWhere((s) => s.isEqual(newSong));
            masterSongPlaylist.updateSongCount();
            // Write to file. 
            await SongSaver.savePlaylist(playlistName: masterSongPlaylist.playlistName, songs: masterSongPlaylist.getCurrentPlaylistSongs());
            playlistNotifier.setPlaylistsAndNotifyListeners(allSongPlaylists); 
            IO.w("Removed.");
            return; 
        }
        
        if (allSongPlaylists[playlistName] == null) return;

        // Remove songs that are equals.
        allSongPlaylists[playlistName]!.getCurrentPlaylistSongs().removeWhere((s) => s.isEqual(newSong));
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

    /// Return the common Song(s) between the [masterSongPlaylist] and Song(s) that can be created from [currentPlaylistPaths].
    /// 
    /// These common Song(s) are Song object(s) from the [masterSongPlaylist.getCurrentPlaylistSongs()].  
    /// Remarks: The order of the original playlist is preserved with LinkedHashMap, but also ensure time complexity constraint. 
    /// The checking of the common Song(s) are only done using the [assetPath], NOT the equality check in [Song] class.
    /// We are guaranteed that Song(s) in [masterSongPlaylist] have unique name AND assetPath, so performing a name check again is redundant.  
    static List<Song> commonValidSongs(List<String> currentPlaylistPaths){
        if (currentPlaylistPaths.isEmpty || SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().isEmpty) return [];
        
        final LinkedHashMap<String, Song> masterSongMap = LinkedHashMap<String, Song>();
        for (Song song in SongRepository.masterSongPlaylist.getCurrentPlaylistSongs()) {
            masterSongMap[song.assetPath] = song;
        }    
        
        return currentPlaylistPaths
            .where((path) => masterSongMap.containsKey(path)) // Where path is the same. 
            .map((path) => masterSongMap[path]!) // Swap the path with the corresponding Song object.  
            .toList();
    }
}