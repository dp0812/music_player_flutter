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
    bool _isLoading = false; 
    bool _isDisposed = false;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
                _loadPlaylists();
            }
        });
    }

    @override
    Widget build(BuildContext context) {
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
            )
        );
    }

    /// Lists of current playlist(s), with bottom padding predefined inside the list. 
    /// 
    /// The playlist(s) list is rebuilt (may not be rebuilt entirely) when the following condition is true: 
    /// 
    /// 1. Changes in the number of song(s), ordering, or corrupted path(s) within any playlist that has triggered a write back to file. 
    /// This is provided by [SongRepository.playlistNotifier] at the current page playlist. The playlist(s) list is rebuilt entirely, ONCE.  
    Widget _buildPlaylistsListWithBottomPadding(){
        return Expanded(
            child: ListenableBuilder(
                listenable: SongRepository.playlistNotifier,
                builder: (context, child) {
                    return PlaylistsList(
                        onPlaylistTap: _gotoPlaylistDetailPage,
                        onPlaylistButtonTap: _deletePlaylist,
                        onPlaylistButtonTapTwo: _renamePlaylist,
                    );
                }
            ),
        );
    }

    /// Normal [MusicPlayerDock] configuration. 
    /// 
    /// Expandable, default in compact mode, showing the title. 
    /// [MusicPlayerDock] is rebuilt when there are specific changes in order to refresh the progress bar and the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                controlsManager: widget.controlsManager,
                audioService: widget.audioService,
            )
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
        _updateLoadingState(true);
        await SongRepository.loadPlaylists();
        _updateLoadingState(false);
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

    void _updateLoadingState(bool isLoading) {
        if (_isDisposed || !mounted) return;
        // Otherwise we delay the call. 
        setState(() {
            _isLoading = isLoading;
        });

        if (widget.onLoadingStateChanged != null && !_isDisposed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_isDisposed) {
                    widget.onLoadingStateChanged!(_isLoading);
                }
            });
        }
        
    }

    @override
    void dispose() {
        _isDisposed = true;
        super.dispose();
    }
}