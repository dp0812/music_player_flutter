import 'package:flutter/material.dart';

import 'package:music_player/entities/playlists_manager.dart';
import 'package:music_player/entities/song_playlist.dart'; 
import 'package:music_player/entities/song_repository.dart';
import 'package:music_player/pages/playlist_detail_page.dart';
import 'package:music_player/pages/playlist_page.dart';
import 'package:music_player/ui_components/playlists_view.dart'; 

/// Provide a way for user to create new, empty playlist. 
/// 
/// These playlists will be stored to the application folder.
/// The view of this page is implemented by the playlists_view.dart file. 
class PlaylistPageState extends State<PlaylistPage> {
    
    // The manager handles all the playlist control logic and dialogs. Equivalence to SongControlsManager in SongScreenState. 
    late final PlaylistsManager _playlistsManager; 

    @override
    void initState() {
        super.initState();
        _playlistsManager = PlaylistsManager(
            context: context,
            notifyListChanged: () {setState(() {/* Rebuild UI*/}); },
            reloadPlaylistsList:  _handleReloadPlaylistList   
        );

        // initial load. 
        _handleReloadPlaylistList();
    }

    /// Reload the playlist list (I.e. how many playlists are being displayed.)
    Future <void> _handleReloadPlaylistList() async{
        await SongRepository.loadPlaylists();
        setState(() {/* Rebuild UI. */});
    }

    // Delegate handling to manager. 
    void _handleAddPlaylist() {
        _playlistsManager.handleAddPlaylist();
    }

    // Handles tapping a playlist item. This navigates to the detail page.
    void _handlePlaylistTap(SongsPlaylist playlist) {
        Navigator.push(
            context, 
            MaterialPageRoute(
                builder: (context) => PlaylistDetailPage(playlist: playlist, audioService: widget.audioService,)
            )
        );
    }

    @override
    void dispose() {
        _playlistsManager.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return PlaylistView(
            onAddPlaylist: _handleAddPlaylist,
            onPlaylistTap: _handlePlaylistTap,
        );
    }
}