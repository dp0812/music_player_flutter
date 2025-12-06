import 'package:music_player/entities/song.dart';
class SongsPlaylist {
    String playlistName; 
    int songCount;
    List<Song> _currentPlaylist = [];
    static int playlistCount = 0; 

    SongsPlaylist({this.playlistName = "Unamed List", this.songCount = 0}){
        playlistCount++;
    }
    /// Add new song to the current playlist, returns true if added successfully. 
    /// If song already exist, this function does nothing and returns false. 
    bool addSong(Song newSong){
        if (isSongInPlaylist(newSong)) return false; 
        _currentPlaylist.add(newSong);
        songCount ++;
        print("Added song ${newSong.title} to playlist: $playlistName ");
        return true; 
    }
    /// Returns true if path of the given Song object already exists in the list. 
    bool isSongInPlaylist(Song someSong){
        return _currentPlaylist.any((song) => song.assetPath == someSong.assetPath);
    }
    
}