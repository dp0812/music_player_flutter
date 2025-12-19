import 'package:flutter/material.dart';
import 'package:music_player/entities/song_playlist.dart';

/// Notify listener when there is a change in the data and the identity of the playlists mapping. 
class PlaylistNotifier extends ChangeNotifier {
    Map<String, SongsPlaylist> _playlists = {};
    Map<String, SongsPlaylist> get playlists => _playlists;
    
    /// Set the input [newPlaylists] as the current map and call [notifyListeners].
    void setPlaylistsAndNotifyListeners(Map<String, SongsPlaylist> newPlaylists) {
        _playlists = newPlaylists;
        notifyListeners();
    }
    
    void updatePlaylist(String playlistName, SongsPlaylist updatedPlaylist) {
        _playlists[playlistName] = updatedPlaylist;
        notifyListeners();
    }
    
    void addPlaylist(String playlistName, SongsPlaylist playlist) {
        _playlists[playlistName] = playlist;
        notifyListeners();
    }
    
    void removePlaylist(String playlistName) {
        _playlists.remove(playlistName);
        notifyListeners();
    }
}