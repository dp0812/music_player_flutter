import 'package:flutter/material.dart';

import 'package:music_player/entities/playlists_manager.dart'; 
import 'package:music_player/entities/song_repository.dart';
import 'package:music_player/pages/playlist_page.dart';
import 'package:music_player/ui_components/playlists_view.dart'; 

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

    Future <void> _handleReloadPlaylistList() async{
        await SongRepository.loadPlaylists();
        setState(() {/* Rebuild UI. */});
    }

    // Delegate handling to manager. 
    void _handleAddPlaylist() {
        _playlistsManager.handleAddPlaylist();
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
        );
    }
}