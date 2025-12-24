import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player/ui_components/delete_song.dart';

import 'song_detail_page.dart';
import 'song_screen.dart';
import '../entities/song.dart';
import '../entities/song_repository.dart';
import '../entities/song_controls_manager.dart';
import '../ui_components/music_player_dock.dart';
// import '../ui_components/now_playing_display.dart';
import '../ui_components/song_list.dart';

/// Provides a list view of the current songs in the playlist alongside with the playback controls dock and the progress bar.
class SongScreenState extends State<SongScreen> {
    bool _isLoading = true;
    Song? _currentSong; 
    bool _isLooping = false; 
    bool _isRandom = false; 
    Duration _currentDuration = Duration.zero; 
    Duration _currentPosition = Duration.zero; 
    
    StreamSubscription<Duration>? _positionSubscription;
    StreamSubscription<Duration>? _durationSubscription;
    StreamSubscription<Song?>? _currentSongSubscription;
    StreamSubscription<bool>? _loopSubscription;
    StreamSubscription<bool>? _randomSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;
    
    @override
    void initState() {
        super.initState();

        // Initialize from widget properties
        _currentSong = widget.currentSong;
        _isLooping = widget.isLooping;
        _isRandom = widget.isRandom;
        _currentDuration = widget.currentDuration;
        _currentPosition = widget.currentPosition;

        _setupStreamListeners();
        _setupPlayerCompletionListener();
        _loadAndSynchronizeSongs();
    }

    @override
    Widget build(BuildContext context) {
        // Placeholder loading screen. 
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            appBar: AppBar(
                title: const Text("Home"),
            ),
            body: Column(
                children: [
                    // Button row
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                                // Add Playlist Button
                                ElevatedButton.icon(
                                    onPressed: _handleAddSong,
                                    icon: const Icon(Icons.playlist_add, size: 18),
                                    label: const Text("Add Song"),
                                ),
                                ElevatedButton.icon(
                                    onPressed: _handleAddMusicDirectory, 
                                    icon: const Icon(Icons.folder, size: 18),
                                    label: const Text("Scan folder"),
                                ),
                            ],
                        ),
                    ),
                    // A thin line to separate the buttons and the list. 
                    const Divider(height: 0), 
                    // List of all current Song(s)
                    Expanded(
                        child: SongList(
                            currentPlaylist: SongRepository.masterSongPlaylist,
                            currentSong: _currentSong,
                            onSongTap: _handleSongTap,
                            onSongButtonTap: _handleSongButtonTap,
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
                    isLooping: _isLooping,
                    isRandom: _isRandom,
                    initialPosition: _currentPosition,
                    initialDuration: _currentDuration,
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
        final bool isSamePlaylist = SongRepository.masterSongPlaylist.playlistName == SongControlsManager.getActivePlaylist().playlistName;  
        if (_currentSong?.assetPath == song.assetPath && widget.audioService.isPlaying && isSamePlaylist) {
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
                return DeleteSong(playlistName: SongRepository.masterSongPlaylist.playlistName, someSong: song);
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

    /// Set up listeners for stream updates
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
    
    /// Completion listener of THIS page. 
    void _setupPlayerCompletionListener() {
        // current 
        _playerCompleteSubscription = widget.audioService.audioPlayer.onPlayerComplete.listen((_) {
            widget.controlsManager.handleSongCompletion();
        });
    }

    /// Clean up and ensure file intergrity when user navigates to this page. 
    Future<void> _loadAndSynchronizeSongs() async {
        setState(() { _isLoading = true; });
        await SongRepository.loadSongs();
        await widget.controlsManager.synchronizePlaybackState(SongRepository.masterSongPlaylist);
        setState(() => _isLoading = false);
    }
    
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