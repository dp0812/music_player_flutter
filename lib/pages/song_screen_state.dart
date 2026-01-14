import 'dart:async';
import 'package:flutter/material.dart';

import 'song_detail_page.dart';
import 'song_screen.dart';
import '../entities/song.dart';
import '../entities/song_repository.dart';
import '../entities/song_search_delegate.dart';
import '../entities/song_controls_manager.dart';
import '../ui_components/delete_song.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/song_list.dart';
import '../ui_components/song_management_bar.dart';

/// Provides a list view of the current songs in the playlist alongside with the playback controls dock and the progress bar.
class SongScreenState extends State<SongScreen> {
    bool _isLoading = true;
    static bool _isFirstTime = true; 
    bool _isDisposed = false;
    
    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
                _loadAndSynchronizeSongs();
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            appBar: AppBar(
                title: const Text("Home"),
                // Search song button. 
                actions: [
                    IconButton(
                        onPressed: _searchSong,
                        icon: const Icon(Icons.search), 
                    ),
                ],
            ),
            body: Stack(
                children: [
                    Column(
                        children: [
                            SongManagementBar(
                                actionOneLabel: "Add Songs",
                                actionTwoLabel: "Scan Folder",
                                buttonActionOne: _handleAddSong,
                                buttonActionTwo: _handleAddMusicDirectory,
                            ),
                            _buildSongsListWithBottomPadding(),
                        ],
                    ),
                    _buildMusicPlayerDock(),
                ],
            ),
        );
    }

    /// Lists of current song(s), with bottom padding predefined inside the list. 
    /// 
    /// The song(s) list is rebuilt (may not be rebuilt entirely) when any of these conditions are true: 
    /// 
    /// 1. Changes in the number of song(s), or corrupted path(s). This is provided by [SongRepository.masterListNotifier]. Song list is rebuilt entirely, ONCE. 
    /// 2. A new song is set as the active song, and the highlight effect needs to be applied. Note that the article "the" indicates there can be exactly ONE active song. 
    /// Uses [SongControlsManager.currentSongNotifier] and [SongControlsManager.isPlayingNotifier] to render the highlight effect of this active song.
    /// 
    /// Remarks: Under item 2, the song list is rebuilt entirely ONCE, then the highlight effect (rotating disc) is rebuilt exactly ONCE every frame. 
    /// The highlight of the tile on rebuilt ONCE, on the frame that the song list is rebuilt entirely. All list tile(s) are not rebuilt during this rotating disc effect. 
    Widget _buildSongsListWithBottomPadding(){
        return Expanded(
            child: ListenableBuilder(
                listenable: SongRepository.masterListNotifier,
                builder: (context, child) {
                    return ValueListenableBuilder<Song?>(
                        valueListenable: widget.controlsManager.currentSongNotifier,
                        builder: (context, currentSong, child) {
                            return ValueListenableBuilder<bool>(
                            valueListenable: widget.controlsManager.isPlayingNotifier,
                            builder: (context, isPlaying, child) {
                                return SongList(
                                    currentPlaylist: SongRepository.masterSongPlaylist,
                                    currentSong: currentSong,
                                    onSongTap: _handleSongTap,
                                    onSongButtonTap: _handleSongButtonTap,
                                    isPlaying: isPlaying,
                                );
                            },
                            );
                        },
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

    /// Push the user to Song Detail Page.
    /// 
    /// Use a fade in transition to hide any potential not fully loaded progress bar. 
    void _goToSongDetailPage(Song song) async {
        await Navigator.push(
            context,
            PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 200),
                pageBuilder: (context, animation, secondaryAnimation) => SongDetailPage(
                    initialSong: song,
                    controlsManager: widget.controlsManager,
                    audioService: widget.audioService,
                    isLooping: widget.controlsManager.isLooping,
                    isRandom: widget.controlsManager.isRandom,
                    initialPosition: widget.controlsManager.currentPosition,
                    initialDuration: widget.controlsManager.currentDuration,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                },
            ),
        );
    }
    
    /// If not currently playing => play the song. If currently playing => go to Song detail page.
    /// 
    /// Check of currently playing song is done using the assetPath in the system.   
    void _handleSongTap(Song song) {
        // Check if this is the currently playing song by name of the playlist. 
        final bool isSamePlaylist = SongRepository.masterSongPlaylist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName;  
        if (widget.controlsManager.currentSong?.assetPath == song.assetPath && widget.audioService.isPlaying && isSamePlaylist) {
            _goToSongDetailPage(song);
            return; 
        } 

        // Otherwise, play this song and set active list = masterSongPlaylist. 
        widget.controlsManager.playSelectedSong(song, SongRepository.masterSongPlaylist);
    }

    /// Delete button that remove from the masterList. 
    /// 
    /// This is ONLY available here. 
    void _handleSongButtonTap(Song song) async {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
                return DeleteSong(
                    playlistName: SongRepository.masterSongPlaylist.playlistName, 
                    someSong: song,
                    isMaster: true,
                );
            },
        );

        SongRepository.masterSongPlaylist.updateSongCount();
        setState(() {/* Rebuild UI */});
    }
    
    /// Let user pick songs from the system file explorer. 
    void _handleAddSong() async {
        await widget.controlsManager.handleAddSong();
    }

    /// Let user pick 1 directory from the system file explorer. 
    void _handleAddMusicDirectory() async {
        await widget.controlsManager.handleAddMusicDirectory();
    }

    /// Search the list of song, to interact with the song searched, one at a time. 
    void _searchSong(){
        showSearch(
            context: context, 
            delegate: SongSearchDelegate(
                availableSongs: SongRepository.masterSongPlaylist.getCurrentPlaylistSongs(),
                onSongTap: _handleSongTap),
        );
    }

    /// Clean up and ensure file intergrity when user navigates to this page. 
    Future<void> _loadAndSynchronizeSongs() async {
        _updateLoadingState(true);
        await SongRepository.loadSongs();
        // Obtain the playlist data for the add to function in song detail page to work on the 1st time the app start. 
        if (_isFirstTime){
            await SongRepository.loadPlaylists(); 
            _isFirstTime = false; 
        }
        await widget.controlsManager.synchronizePlaybackState(SongRepository.masterSongPlaylist);
        _updateLoadingState(false);
    }

    void _updateLoadingState(bool isLoading) {
        if (_isDisposed || !mounted) return;
        // Otherwise we delay the call. 
        setState(() {
            _isLoading = isLoading;
        });

        // Notify parent with safety check
        if (widget.onLoadingStateChanged != null && !_isDisposed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_isDisposed) {
                    widget.onLoadingStateChanged!(isLoading);
                }
            });
        }
    }
    
    @override
    void dispose() {
        _isDisposed = true;
        widget.onLoadingStateChanged?.call(false);
        super.dispose();
    }
}