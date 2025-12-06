import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'package:music_player/entities/song.dart';
import 'song_saver.dart';

class SongRepository {
  
    /// Store all the Song objects in the supplier directory. Please make reference to this to the full song list. 
    static List<Song> songCollection = [];

    // Static function to check file existence.
    static Future<bool> isSongFileAvailable(String path) async {
        final cleanPath = path.trim();
        return await File(cleanPath).exists();
    }

    /// Now loads a special file with the path of the Song object. 
    /// This is persistent, and allow user added songs to be load the next time the program start again. 
    static Future<void> loadSongs() async {
        songCollection.clear(); // Clear any previous songs in the list. 
        // Load user-added songs from the persistent text file
        final List<String> savedPaths = await SongSaver.loadSavedSongPaths();
        final List<String> validPaths = [];
        final List<String> invalidPathsForRemoval = [];

        for (String path in savedPaths) {
            // Check file intergrity.
            if (await isSongFileAvailable(path)) { 
                validPaths.add(path); // This path is valid, keep it
                final String fileName = p.basenameWithoutExtension(path); 
                songCollection.add(Song(title: fileName, assetPath: path));
            } else {
                print("Invalid/Missing file detected, removing path: $path");
                invalidPathsForRemoval.add(path);
            }
        }
        // If length saved != length valid path => rewrite. 
        if (savedPaths.length != validPaths.length ) {
            print("savedPaths.length = ${savedPaths.length} and validPaths.length = ${validPaths.length}");
            await SongSaver.rewriteSavedSongPaths(validPaths);
        }
        // This is NOT redundant. If this check is excluded, the UI will contain invalid songs on the list. 
        for (String invalidPath in invalidPathsForRemoval){
            songCollection.removeWhere((song) => song.assetPath == invalidPath);
        }
    }

    /// Prompt user to add 1 songs, or multiple songs (MUST be .mp3 file)
    /// This safely ensure that there is no race condition by using await on the master file.  
    static Future<int> addSongsFromUserSelection() async {
        try {
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
                final Song newSong = Song(title: fileName, assetPath: filePath);
                if (songCollection.any((song) => song.assetPath == filePath)){ // Any dupplicate path exits => skip. 
                    print("Skipped adding duplicate song: ${newSong.title}");
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
            print('Error selecting files: $e'); 
            return 0;
        }
    }
}