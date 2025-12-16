import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:music_player/entities/song_playlist.dart';
import 'package:music_player/entities/song.dart';
import 'package:music_player/utilities/io_print.dart';
import 'song_saver.dart';

/// Holds actual Song objects data. Contain a master List named [songCollection], and a Map of sub list, named [allSongPlaylists]. 
class SongRepository {
    /// After changing the [allSongPlaylists] map, notify the listener with: playlistNotifier.value = Map.from(allSongPlaylists);
    static final ValueNotifier<Map<String, SongsPlaylist>> playlistNotifier = ValueNotifier<Map<String, SongsPlaylist>>({});
    /// Store all the Song objects in the supplier directory. Please make reference to this to the full song list. 
    static List<Song> songCollection = [];
    /// Each playlist name is a key, connect to the list of songs. 
    static Map<String,SongsPlaylist> allSongPlaylists = {};

    /// Load playlist data in the application directory and populate the map [SongRepository.allSongPlaylists]
    /// 
    /// For every playlists and songs in each playlist, the functions check the [Song.assetPath]. 
    /// If assetPath can be matched with data in the masterList.txt, a new Song object with that path will be add to the playlist. 
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
                int songIndex = songCollection.indexWhere((s) => s.assetPath == path);
                if (songIndex == -1){ //not found. 
                    invalidSongs++;
                    continue; 
                }  
                Song validSong = songCollection[songIndex];
                newPlaylist.addSong(validSong);
                songsAdded++;
            }
            allSongPlaylists[name] = newPlaylist;
            IO.i('Loaded playlist "$name" with $songsAdded songs.');
            // No invalid songs => next playlist. 
            if (invalidSongs == 0 ) continue;   
            // Otherwise rewrite this valid playlist back to the file
            File currentPlaylistFile = await SongSaver.getPlaylistFile(playlistName: name);
            await SongSaver.rewriteSavedSongPaths(newPlaylist.getAllPathsInPlaylist(), songPathFile: currentPlaylistFile);
            IO.i('Write back to playlist "$name" completed!');

        }
        playlistNotifier.value = Map.from(allSongPlaylists);
    }

    /// Loads the [masterFile.txt] in the application directory, and retrieve the [Song.assetPath] stored in that file. 
    /// 
    /// Remove all invalid Paths (Path that cannot be find on the current system) 
    /// and rewrite the masterFile.txt to contain only valid paths.  
    /// Remove all Song objects containing the invalid paths from the SongRepository storage. 
    /// 
    /// Does not update info in the file containing the playlist. Call [loadPlaylists] to do this!
    static Future<void> loadSongs() async {
        songCollection.clear(); // Clear any previous songs in the list. 
        // Load user-added songs from the persistent text file
        File currentWorkingMasterFile = await  SongSaver.getMasterFile();
        final List<String> savedPaths = await SongSaver.loadSavedSongPaths(songPathFile: currentWorkingMasterFile);
        final List<String> validPaths = [];
        final List<String> invalidPathsForRemoval = [];

        for (String path in savedPaths) {
            // Check file intergrity.
            if (await isSongFileAvailable(path)) { 
                validPaths.add(path); // This path is valid, keep it
                final String fileName = p.basenameWithoutExtension(path); 
                songCollection.add(await Song.create(title: fileName, assetPath: path));
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
            songCollection.removeWhere((song) => song.assetPath == invalidPath);
        }
    }

    /// Add a new playlist with [name], replacing all spaces with underscores.
    /// 
    /// If there exist another playlist with [name], no new playlist is created.  
    /// The newly added playlist will be write to disk. 
    static Future<bool> addPlaylist(String name) async {
        // Normalize the name to check for existence
        final normalizedName = name.trim(); 
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
        playlistNotifier.value = Map.from(allSongPlaylists); //Notify listener. 
        return true;
    }

    /// This should only be used when the caller guarantees that the playlist exists. 
    /// 
    /// Notify all of its listener if a new song is added, otherwise do nothing. 
    static Future<void> addSongsFromCollection({required String playlistName, required Song newSong}) async{
        if (allSongPlaylists[playlistName]!.addSong(newSong)) {
            playlistNotifier.value = Map.from(allSongPlaylists); //Notify listener. 
        }
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
                if (songCollection.any((song) => song.assetPath == filePath)){ // Any dupplicate path exits => skip. 
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                // If pass both checks => must be unique. 
                songCollection.add(newSong); 
                await SongSaver.saveSongPath(newSong); // await added to avoid race condition when writing the path to the txt file. 
                songsAdded++;
            }
            return songsAdded;
        } catch (e) {
            // Log the error but return 0 to indicate no songs were added
            IO.e("Error selecting files: ", error: e); 
            return 0;
        }
    }

    /// Returns true if the path provided leads to a valid, existing file. 
    static Future<bool> isSongFileAvailable(String path) async {
        final cleanPath = path.trim();
        return await File(cleanPath).exists();
    }
}