import 'dart:async';
import 'package:flutter/material.dart';

import 'playlist_detail_page.dart';
import 'playlist_page.dart';
import '../entities/song.dart';
import '../entities/song_playlist.dart'; 
import '../entities/song_repository.dart';
import '../ui_components/add_playlist.dart';
import '../ui_components/delete_playlist.dart';
import '../ui_components/playlists_list.dart'; 
import '../ui_components/music_player_dock.dart';

/// This page allows the user to still have controls over the song that is being played. 
/// 
/// This controls include 2 elements: 
/// 1. The playback controls (your buttons sitting on the dock)
/// 2. The progress bar (on top - will be changed in the future to be close to the playback controls).
class PlaylistPageState extends State<PlaylistPage> {
    
    // Local state for playback
    Song? _currentSong;
    bool _isLooping = false;
    bool _isRandom = false;
    Duration _currentDuration = Duration.zero;
    Duration _currentPosition = Duration.zero;
    
    // Stream subscriptions for listening to playback updates
    StreamSubscription<Duration>? _positionSubscription;
    StreamSubscription<Duration>? _durationSubscription;
    StreamSubscription<Song?>? _currentSongSubscription;
    StreamSubscription<bool>? _loopSubscription;
    StreamSubscription<bool>? _randomSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;

    @override
    void initState() {
        super.initState();
        
        // Initialize local state from widget properties
        _currentSong = widget.currentSong;
        _isLooping = widget.isLooping;
        _isRandom = widget.isRandom;
        _currentDuration = widget.currentDuration;
        _currentPosition = widget.currentPosition;
        
        // Set up listeners for playback state changes
        _setupStreamListeners();
        _setupPlayerCompletionListener(); 
        _loadPlaylists();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Library"),
            ),
            body: Column(
                children: [
                    // Button row
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                // Add Playlist Button
                                ElevatedButton.icon(
                                    onPressed: _addPlaylistByName,
                                    icon: const Icon(Icons.playlist_add, size: 18),
                                    label: const Text("New Playlist"),
                                ),
                            ],
                        ),
                    ),
                    // A thin line to separate the buttons and the list. 
                    const Divider(height: 0), 
                    // List of all current Playlist
                    Expanded(
                        child: PlaylistsList(
                            onPlaylistTap: _gotoPlaylistDetailPage,
                            onPlaylistButtonTap: _deletePlaylist,
                        ),
                    ),
                ],
            ),
            // The bottom music player dock, include progress bar, title and buttons for next/previous, pause/play/resume, loop/random.
            bottomNavigationBar: MusicPlayerDock(
                currentSong: _currentSong,
                duration: _currentDuration,
                position: _currentPosition,
                onSeek: widget.controlsManager.handleSeek,
                
                audioService: widget.audioService,
                onNextSong: widget.controlsManager.gotoNextSong, 
                onPreviousSong: widget.controlsManager.gotoPreviousSong, 
                onPlayPauseResume: widget.controlsManager.handlePlayResumePause, 
                onStop: widget.controlsManager.stop,
                onToggleLoop: widget.controlsManager.toggleLoop,
                isLooping: _isLooping,
                onToggleRandom: widget.controlsManager.toggleRandom,
                isRandom: _isRandom,
            ),
        );
    }

    /// Navigates to the PlaylistDetailPage. 
    void _gotoPlaylistDetailPage(SongsPlaylist playlist) async {
        await Navigator.push(
            context,
            PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 200),
                pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailPage(
                    playlist: playlist,
                    audioService: widget.audioService,
                    controlsManager: widget.controlsManager,
                    currentSong: _currentSong,
                    isLooping: _isLooping,
                    isRandom: _isRandom,
                    currentDuration: _currentDuration,
                    currentPosition: _currentPosition,
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

    /// Refresh UI of progress bar and playback controls dock based on listener.
    void _setupStreamListeners() {
        // Progress bar position changes.
        _positionSubscription = widget.controlsManager.onPositionChanged.listen((position) {
            if (mounted) setState(() => _currentPosition = position);
        });

        // Progress bar total duration changes.
        _durationSubscription = widget.audioService.onDurationChanged.listen((duration) {
            if (mounted) setState(() => _currentDuration = duration);
        });

        // Current song changes.
        _currentSongSubscription = widget.controlsManager.onCurrentSongChanged.listen((song) {
            if (mounted) setState(() => _currentSong = song);
        });

        // Loop mode changes.
        _loopSubscription = widget.controlsManager.onLoopChanged.listen((isLooping) {
            if (mounted) setState(() =>_isLooping = isLooping);
        });

        // Random mode changes.
        _randomSubscription = widget.controlsManager.onRandomChanged.listen((isRandom) {
            if (mounted) setState(() =>_isRandom = isRandom);
        });
    }
    
    /// Set up player completion listener specific to this page.
    void _setupPlayerCompletionListener() {
        // current. 
        _playerCompleteSubscription = widget.audioService.audioPlayer.onPlayerComplete.listen((_) {
            widget.controlsManager.handleSongCompletion();
        });
    }

    /// Clean up all subscriptions.
    @override
    void dispose() {
        _positionSubscription?.cancel();
        _durationSubscription?.cancel();
        _currentSongSubscription?.cancel();
        _loopSubscription?.cancel();
        _randomSubscription?.cancel();
        _playerCompleteSubscription?.cancel();
        super.dispose();
    }
}