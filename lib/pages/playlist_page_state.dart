import 'dart:async';
import 'package:flutter/material.dart';

import 'playlist_detail_page.dart';
import 'playlist_page.dart';
import '../entities/song_playlist.dart'; 
import '../entities/song_repository.dart';
import '../ui_components/add_playlist.dart';
import '../ui_components/delete_playlist.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/playlists_list.dart'; 
import '../ui_components/rename_playlist.dart';
import '../ui_components/song_management_bar.dart';

/// This page display an overview of all playlist(s) and give user the music dock to control the song being played. 
class PlaylistPageState extends State<PlaylistPage> {

    @override
    void initState() {
        super.initState();
        _loadPlaylists();
    }

    @override
    Widget build(BuildContext context) {
        // Rebuild when controlsManager changes.
        return ListenableBuilder(
            listenable: widget.controlsManager,
            builder: (context, child) {
                return Scaffold(
                    appBar: AppBar(
                        title: const Text("Library"),
                    ),
                    body: Stack(
                        children: [
                            Column(
                                children: [
                                    SongManagementBar(
                                        actionOneLabel: "New Playlist",
                                        buttonActionOne: _addPlaylistByName,
                                    ),
                                    _buildPlaylistsListWithBottomPadding(),
                                ],
                            ),
                            _buildMusicPlayerDock(),
                        ],
                    ),
                );
            },
        );
    }

    /// Lists of current Playlist(s), with bottom padding predefined inside the list. 
    /// 
    /// This padding (180) is just enough for the dock in compact mode if scroll to list bottom.
    Widget _buildPlaylistsListWithBottomPadding(){
        return Expanded(
            child: PlaylistsList(
                onPlaylistTap: _gotoPlaylistDetailPage,
                onPlaylistButtonTap: _deletePlaylist,
                onPlaylistButtonTapTwo: _renamePlaylist,
            ),
        );
    }

    /// Normal [MusicPlayerDock] configuration. 
    /// 
    /// Expandable, default in compact mode, showing the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                currentSong: widget.controlsManager.currentSong,
                duration: widget.controlsManager.currentDuration,
                position: widget.controlsManager.currentPosition,
                onSeek: widget.controlsManager.handleSeek,
                pushToDetail: widget.controlsManager.pushToSongDetailPage,
                
                audioService: widget.audioService,
                onNextSong: widget.controlsManager.gotoNextSong, 
                onPreviousSong: widget.controlsManager.gotoPreviousSong, 
                onPlayPauseResume: widget.controlsManager.handlePlayResumePause, 
                onStop: widget.controlsManager.stop,
                onToggleLoop: widget.controlsManager.toggleLoop,
                isLooping: widget.controlsManager.isLooping,
                onToggleRandom: widget.controlsManager.toggleRandom,
                isRandom: widget.controlsManager.isRandom,
            ),
        );
    }

    /// Navigates to the PlaylistDetailPage. 
    void _gotoPlaylistDetailPage(SongsPlaylist playlist) async {
        await Navigator.push(
            context,
            PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailPage(
                    playlist: playlist,
                    audioService: widget.audioService,
                    controlsManager: widget.controlsManager,
                    currentSong: widget.controlsManager.currentSong,
                    isLooping: widget.controlsManager.isLooping,
                    isRandom: widget.controlsManager.isRandom,
                    currentDuration: widget.controlsManager.currentDuration,
                    currentPosition: widget.controlsManager.currentPosition,
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
    
    /// Prompt user to enter new playlist name to replace the old one. 
    void _renamePlaylist(SongsPlaylist playlist) async {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
                return RenamePlaylist(context: context, currentPlaylistName: playlist.playlistName);
            },
        );

        setState(() {/* Rebuild UI */});
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
}