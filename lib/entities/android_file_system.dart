import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'song.dart';
import 'song_repository.dart';
import 'song_saver.dart';
import '../utilities/io_print.dart';

/// Android specific handling for the scanning of files. 
class AndroidFileSystem {
    /// Scan Android music directory. If no song found, move to download dir. 
    static Future<int> scanAndroidMusicDirectory() async {
        try {

            bool decision = await requestAndroidPermission();
            // Without the permission, there will not be an exception, but the scan will result in nothing. 
            if (!decision) IO.w("Scanning without permission."); 
            
            IO.i("Scanning Android music directory...");
            final String musicPath = await AndroidPathProvider.musicPath;
            if (musicPath.isEmpty) IO.w("Could not get Android music directory path");  
            
            IO.i("Music directory path: $musicPath");
            Directory musicDir = Directory(musicPath);
            
            if (!await musicDir.exists()) IO.w("Music directory does not exist: $musicPath");
            
            int songsAdded = 0;
            
            // List all files in music directory (including subdirectories)
            Stream<FileSystemEntity> fileList = musicDir.list(recursive: true, followLinks: false);
            List<String> mp3PathsList = await SongRepository.getMP3FilesFromStream(fileList);
            
            for (String somePath in mp3PathsList){
                final String fileName = p.basenameWithoutExtension(somePath); 
                final Song newSong = await Song.create(title: fileName, assetPath: somePath);
                if (SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().any((song) => newSong.isEqual(song))){
                    IO.t("Skipped adding duplicate song: ${newSong.title}");
                    continue;
                }
                SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
                await SongSaver.saveSongPath(newSong);
                songsAdded++;
                if (songsAdded % 10 == 0) IO.i("Added $songsAdded song(s) so far...");
            }
            /// Check for the download directory if nothing is found in music directory. 
            if (songsAdded == 0) {
                IO.i("No music files found in $musicPath");
                IO.i("Trying downloads directory...");
                songsAdded = await _scanAndroidDownloadDir();
            }
            
            IO.i("Android music scanning completed. Total song(s) added: $songsAdded song(s)!");
            return songsAdded;

        } catch (e) {
            IO.e("Error scanning Android directory: ", error: e);
            return await SongRepository.addSongsFromUserSelection();
        }
    }

    /// Scan Android download directory. If no songs found, there is some serious problem here. 
    static Future <int> _scanAndroidDownloadDir() async {
        // Try downloads directory as fallback
        final String downloadsPath = await AndroidPathProvider.downloadsPath;
        int songsAdded = 0; 
        if (downloadsPath.isEmpty) return 0;

        Directory downloadsDir = Directory(downloadsPath);
        
        if (!await downloadsDir.exists()) {
            IO.w("Download directory does not exist: $downloadsPath");
            return await SongRepository.addSongsFromUserSelection();
        }
        
        Stream<FileSystemEntity> fileList = downloadsDir.list(recursive: true, followLinks: false);
        List<String> mp3PathsList = await SongRepository.getMP3FilesFromStream(fileList);
        
        for (String somePath in mp3PathsList){
            final String fileName = p.basenameWithoutExtension(somePath); 
            final Song newSong = await Song.create(title: fileName, assetPath: somePath);
            if (SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().any((song) => newSong.isEqual(song))){
                IO.t("Skipped adding duplicate song: ${newSong.title}");
                continue;
            }
            SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().add(newSong); 
            await SongSaver.saveSongPath(newSong);
            songsAdded++;
            if (songsAdded % 10 == 0) IO.i("Added $songsAdded song(s) so far...");
        }
        IO.i("Android download directory scan completed. Total song(s) added: $songsAdded song(s)!");
        return songsAdded; 
    }

    /// Request audio permission on Android device. Return true if permission for audio is granted, otherwise false. 
    /// 
    /// This request can only be performed after the following are guaranteed: 
    /// 1. gradle.properties has these 2 lines: [android.useAndroidX=true] and [android.enableJetifier=true]
    /// 2. AndroidManifest.xml has the permission tag (See the AndroidManifest.xml file for more info).
    static Future <bool> requestAndroidPermission() async {
        IO.d("Waiting for permission on Android device.");
        var status1 = await Permission.audio.request();
        if (status1.isDenied) IO.w("No audio permission granted.");
        if (status1.isGranted) IO.i("Granted audio permission on Android device. Proceed.");
        return status1.isGranted;
    }
}