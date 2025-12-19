import 'package:flutter/material.dart';

import 'package:music_player/entities/song_playlist.dart'; 
import 'package:music_player/entities/song_repository.dart';
import 'package:music_player/pages/playlist_detail_page.dart';
import 'package:music_player/pages/playlist_page.dart';
import 'package:music_player/ui_components/add_playlist.dart';
import 'package:music_player/ui_components/delete_playlist.dart';
import 'package:music_player/ui_components/view_playlists.dart'; 

/// Provide a way for user to create new, empty playlist. 
/// 
/// These playlists will be stored to the application folder.
/// The view of this page is implemented by the playlists_view.dart file. 
class PlaylistPageState extends State<PlaylistPage> {

    @override
    void initState() {
        super.initState();
        // initial load. 
        _loadPlaylists();
    }

    /// Load the playlist list from the file system. 
    Future <void> _loadPlaylists() async {
        await SongRepository.loadPlaylists();
        setState(() {/* Rebuild UI. */});
    }
    
    /// Prompt user to enter new playlist name for creation. 
    void _addPlaylistByName() async {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
                return AddPlaylist(context: context);
            },
        );

        setState(() {/* Rebuild UI */});
    }

    /// Navigates to the PlaylistDetailPage. 
    void _gotoPlaylistDetailPage(SongsPlaylist playlist) async {
        await Navigator.push(
            context,
            PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 100),
                pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailPage(
                    playlist: playlist, audioService: widget.audioService
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                        opacity: animation,
                        child: child,
                    );
                },
            ),
        );
    }

    /// Delete [playlist] from both the current Repository and the file system. 
    void _deletePlaylist(SongsPlaylist playlist) async {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
                return DeletePlaylist(playlistName: playlist.playlistName);
            },
        );

        setState(() {/* Rebuild UI */});
    }

    @override
    void dispose() {
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return PlaylistView(
            onAddPlaylist: _addPlaylistByName,
            onPlaylistTap: _gotoPlaylistDetailPage,
            onPlaylistButtonTap: _deletePlaylist,
        );
    }
}