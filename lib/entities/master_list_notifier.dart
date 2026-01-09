import 'package:flutter/material.dart';

import 'song_playlist.dart';

/// Notify listener when there is a change in the data and the identity of the master list. 
/// 
/// Used by the [SongRepository]. 
class MasterListNotifier extends ChangeNotifier {
    SongsPlaylist _masterPlaylist = SongsPlaylist();
    SongsPlaylist get masterPlaylist => _masterPlaylist;
    
    /// Set the input [newPlaylists] as the current map and call [notifyListeners].
    void setMasterListAndNotifyListeners(SongsPlaylist newPlaylist) {
        _masterPlaylist = newPlaylist;
        notifyListeners();
    }
}