import 'package:music_player/entities/song.dart';
import 'package:music_player/entities/song_saver.dart';
import 'package:music_player/utilities/io_print.dart';

/// Compose of multiple Songs, provide quick access to all their assetPath and title. 
class SongsPlaylist {
    String playlistName; 
    int songCount;
    List<Song> _currentPlaylist = [];
    static int playlistCount = 0; 

    SongsPlaylist({this.playlistName = "Unamed List", this.songCount = 0, List<Song>? songLists}){ 
        playlistCount++;
        _currentPlaylist = [];
        if (songLists != null) {
            songCount = songLists.length;
            _currentPlaylist.addAll(songLists);
        }
    }

    /// Add [newSong] to the current playlist and the correct file in the application directory. 
    ///
    /// If song already exist, this function does nothing and returns false.
    /// Otherwise increment number of song in playlist and returns true.  
    bool addSong(Song newSong){
        if (isSongInPlaylist(newSong)) return false; 
        _currentPlaylist.add(newSong);
        // save to file. 
        SongSaver.saveSongPath(newSong, playlistName: playlistName);
        songCount ++;
        IO.t("Added song ${newSong.title} to playlist: $playlistName ");
        return true; 
    }

    /// Returns true if path of the given Song object already exists in the list. 
    bool isSongInPlaylist(Song someSong){
        return _currentPlaylist.any((song) => song.assetPath == someSong.assetPath);
    }

    /// Returns the list of Songs an instance holds. 
    List<Song> getCurrentPlaylistSongs (){
        return _currentPlaylist;
    }

    /// Update songCount of this instance.
    void updateSongCount() {
        songCount = _currentPlaylist.length;
    }
    
    /// Returns the list of all paths of all Song in the current playlist.
    List<String> getAllPathsInPlaylist(){
        List<String> currentPaths = [];
        for (Song someSong in _currentPlaylist){
            currentPaths.add(someSong.assetPath);
        }
        return currentPaths;
    }

    /// Replace all songs in the playlist with [newSongs]
    void replaceSongs(List<Song> newSongs) {
        _currentPlaylist.clear();
        _currentPlaylist.addAll(newSongs);
    }
}