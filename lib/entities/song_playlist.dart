import '../entities/song.dart';
import '../entities/song_saver.dart';

/// Compose of multiple Songs, provide quick access to all their assetPath and title. 
class SongsPlaylist {
    /// Name is designed to be unique when you insert them to the map. 
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
        if (_isSongInPlaylist(newSong)) return false; 
        _currentPlaylist.add(newSong);
        // save to file. 
        SongSaver.saveSongPath(newSong, playlistName: playlistName);
        songCount ++;
        return true; 
    }

    /// Returns true if path of the given Song object already exists in the list. 
    bool _isSongInPlaylist(Song someSong){
        return _currentPlaylist.any((song) => song.assetPath == someSong.assetPath);
    }

    /// Returns the list of Songs an instance holds. 
    List<Song> getCurrentPlaylistSongs () => _currentPlaylist;

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
        updateSongCount();
    }

    /// Add all non dupplicate song in [newSongs] to the playlist. 
    bool addAll(List<Song> newSongs){
        bool updated = false; 
        for (Song someSong in newSongs){
            if (!_isSongInPlaylist(someSong)){
                _currentPlaylist.add(someSong);
                updated = true;
            }  
        }
        updateSongCount();
        return updated;
    }

    /// Invoke .clear() on the current List of Song(s).
    void clearSongs() => _currentPlaylist.clear();
    
}