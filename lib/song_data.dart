import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:music_player/entities/song.dart';

class SongData {
  
    /// Store all the Song objects in the supplier directory. Please make reference to this to the full song list. 
    static List<Song> availableSongs = [];

    /// Get the path for the user to drop files
    static Future<String> _getMusicDirectoryPath() async {
        // There are specialized version of the getApplicationDocumentsDirectory, based on the OS. 
        final directory = await getApplicationDocumentsDirectory();
        // Join the path segments to create a 'Music' subdirectory
        // This is the dedicated folder where users should drop MP3s.
        final musicDirPath = p.join(directory.path, 'Music');
        
        final musicDir = Directory(musicDirPath);
        if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
        }
        
        return musicDirPath;
    }

    /// Scan the directory and build the Song list
    static Future<void> loadSongsFromFiles() async {
        final musicDirPath = await _getMusicDirectoryPath();
        final directory = Directory(musicDirPath);
        // List all file system entities (files, folders, links)
        final fileEntities = directory.listSync(recursive: false);
        final List<Song> songs = [];
        
        for (var entity in fileEntities) {
            if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
                final filePath = entity.path;
                //Remove extension from name. 
                final fileName = p.basenameWithoutExtension(filePath);
                //assetPath = full file path            
                songs.add(Song(title: fileName, assetPath: filePath));
            }
        }
        availableSongs = songs; //Update the static list
        //Where user should drop files
        print('DROP-IN FOLDER: $musicDirPath');
    }
}