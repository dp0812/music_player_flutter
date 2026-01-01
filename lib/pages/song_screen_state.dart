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
    
    @override
    void initState() {
        super.initState();
        _loadAndSynchronizeSongs();
    }

    @override
    Widget build(BuildContext context) {
        // Rebuild when controlsManager changes.
        return ListenableBuilder(
            listenable: widget.controlsManager,
            builder: (context, child) {
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
            },
        );
    }

    /// Lists of current song(s), with bottom padding predefined inside the list. 
    /// 
    /// This padding (180) is just enough for the dock in compact mode if scroll to list bottom.
    Widget _buildSongsListWithBottomPadding(){
        return Expanded(
            child: SongList(
                currentPlaylist: SongRepository.masterSongPlaylist,
                currentSong: widget.controlsManager.currentSong,
                onSongTap: _handleSongTap,
                onSongButtonTap: _handleSongButtonTap,
                isPlaying: widget.controlsManager.audioService.isPlaying,
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

    /// Push the user to Song Detail Page
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
        setState(() => _isLoading = true);
        await SongRepository.loadSongs();
        // Obtain the playlist data for the add to function in song detail page to work on the 1st time the app start. 
        if (_isFirstTime){
            await SongRepository.loadPlaylists(); 
            _isFirstTime = false; 
        }
        await widget.controlsManager.synchronizePlaybackState(SongRepository.masterSongPlaylist);
        setState(() => _isLoading = false);
    }
    
    @override
    void dispose() {
        super.dispose();
    }
}