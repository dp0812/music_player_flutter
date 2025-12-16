import 'dart:async';
import 'package:flutter/material.dart';

import 'package:music_player/pages/song_detail_page.dart';

import '../ui_components/playback_controls.dart';
import '../ui_components/now_playing_display.dart';
import '../ui_components/song_list.dart';
import '../entities/song.dart';
import '../entities/song_repository.dart';
import 'song_screen.dart';
 
import '../entities/song_controls_manager.dart';

/// State class responsible for invoking the large majority of functions to the user, such as progress bar, play, pause, resume, etc
class SongScreenState extends State<SongScreen> {
    Song? _currentSong;
    bool _isLoading = true; 
    bool _isLooping = false;
    Duration _currentDuration = Duration.zero; 
    Duration _currentPosition = Duration.zero; 

    late final SongControlsManager _controlsManager;
    
    @override
    void initState() {
        super.initState();

        // Reset everything when screen is initialized
        _currentSong = null;
        _currentDuration = Duration.zero;
        _currentPosition = Duration.zero;
        
        // Stop any playing audio from previous instances
        widget.audioService.stop();

        // Initialize control manager - handles all interactions. 
        _controlsManager = SongControlsManager(
            audioService: widget.audioService,
            context: context,
            // Implementation of Getters.
            getCurrentSong: () => _currentSong,
            getIsLooping: () => _isLooping,
            getCurrentSongList: () => SongRepository.songCollection,  // Send in current working song list. 
            // Implementation of Setters (to update state and trigger setState).
            setCurrentSong: (song) {setState(() { _currentSong = song; });},
            setIsLooping: (isLooping) {setState(() { _isLooping = isLooping; });},
            // Implementation of resetPlaybackState. 
            resetPlaybackState: () {
                setState(() {
                    _currentSong = null;
                    _currentDuration = Duration.zero;
                    _currentPosition = Duration.zero;
                });
            },
            setCurrentPosition: (position) {setState(() { _currentPosition = position; });},
            setCurrentDuration: (duration) {setState(() { _currentDuration = duration; });},
            notifySongListChanged: () {
                setState(() { /* Empty setState to trigger UI rebuild */ });
            },
            reloadSongList: _loadAndSynchronizeSongs,
        );
        _loadAndSynchronizeSongs();
    }

    /// Cancel all streams and dispose all services when app is terminated. 
    @override
    void dispose() {
        widget.audioService.stop();
        _controlsManager.cancelAudioStreams();
        super.dispose();
    }

    /// Load available songs and synchronize playback state. 
    Future<void> _loadAndSynchronizeSongs() async {
        if (!mounted) return;        
        setState(() { _isLoading = true; });
        await SongRepository.loadSongs(); 
        await _controlsManager.synchronizePlaybackState();
        if (mounted) {
            setState(() { _isLoading = false; });
        }
    }

    // PlaybackControls delegate to SongControlsManager 
    void _handleAddSong() async {
        await _controlsManager.handleAddSong();
    }
    //void _handleSongTap(Song song) => _controlsManager.playSelectedSong(song);

    /// If not currently playing => play the song. If currently playing => go to Song detail page.
    /// 
    /// Check of currently playing song is done using the assetPath in the system.   
    void _handleSongTap(Song song) {
        // Check if this is the currently playing song
        if (_currentSong?.assetPath == song.assetPath && widget.audioService.isPlaying) {
            _goToSongDetailPage(song);
        } else {
            _controlsManager.playSelectedSong(song);
        }
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
                    controlsManager: _controlsManager,
                    audioService: widget.audioService,
                    initialPosition: _currentPosition,
                    initialDuration: _currentDuration,
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
    void _handlePlayResumePause() => _controlsManager.handlePlayResumePause();
    void _handleStop() => _controlsManager.stop();
    void _toggleLoop() => _controlsManager.toggleLoop();


    // NowPlayingDisplay delegate to SongControlsManager 
    void _handleSeek(double value) => _controlsManager.handleSeek(value);

    @override
    Widget build (BuildContext context){
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            appBar: AppBar(
                title: const Text("MP3 Player Test Version"),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.add_to_photos),
                        onPressed: _handleAddSong, // Triggers the file picker
                        tooltip: "Add Song",
                    ),
                ],
                ),
            body: Column(
                children: [
                    NowPlayingDisplay(
                        currentSong: _currentSong,
                        duration: _currentDuration,
                        position: _currentPosition,
                        onSeek: _handleSeek,
                    ),
                    Expanded(
                        child: SongList(
                            songs: SongRepository.songCollection, 
                            currentSong: _currentSong,
                            onSongTap: _handleSongTap,
                        ),
                    ),
                ],
            ),
            bottomNavigationBar: PlaybackControls(
                audioService: widget.audioService,
                onPlayPauseResume: _handlePlayResumePause,
                onStop: _handleStop,
                onToggleLoop: _toggleLoop,
                isLooping: _isLooping,
            ),
        );
    }
}