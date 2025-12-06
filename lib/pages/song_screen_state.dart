import 'dart:async';
import 'package:flutter/material.dart';

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

    StreamSubscription<Duration>? _onPositionSubscription;
    StreamSubscription<Duration>? _onDurationSubscription;

    late final SongControlsManager _controlsManager;
    
    @override
    void initState() {
        super.initState();
        // Initialize control manager - handles all interactions. 
        _controlsManager = SongControlsManager(
            audioService: widget.audioService,
            context: context,
            // Implementation of Getters.
            getCurrentSong: () => _currentSong,
            getIsLooping: () => _isLooping,
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
            notifySongListChanged: () {
                setState(() { /* Empty setState to trigger UI rebuild */ });
            },
            reloadSongList: _loadSongs,
        );

        _loadSongs();
        
        // Rebuild UI based on current stream listener output. 
        // Create Duration. 
        _onDurationSubscription = widget.audioService.onDurationChanged.listen((d) {
            setState(() { _currentDuration = d; });
        });
        // Change current position. 
        _onPositionSubscription = widget.audioService.onPositionChanged.listen((p) {
            setState(() { _currentPosition = p; });
        });
    }

    /// Cancel all streams and dispose all services when app is terminated. 
    @override
    void dispose() {
        _onPositionSubscription?.cancel();
        _onDurationSubscription?.cancel();
        widget.audioService.dispose();
        super.dispose();
    }

    /// Load available songs
    Future<void> _loadSongs() async {
        await SongRepository.loadSongs(onListCleaned: (){
            setState(() {/* Try to rebuild the UI */});
        });
        setState(() {
            _isLoading = false;
        });
    }

    // PlaybackControls delegate to SongControlsManager 
    void _handleAddSong() async {
        await _controlsManager.handleAddSong();
    }
    void _handleSongTap(Song song) => _controlsManager.playSelectedSong(song);
    void _handlePlayResumePause() => _controlsManager.handlePlayResumePause();
    void _handleStop() => _controlsManager.stop();
    void _toggleLoop() => _controlsManager.toggleLoop();


    // NowPlayingDisplay delegate to SongControlsManager 
    void _handleSeek(double value) => _controlsManager.handleSeek(value);

    @override
    Widget build (BuildContext context){
        //_loadSongs();
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            appBar: AppBar(
                title: const Text('MP3 Player Test Version'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.add_to_photos),
                        onPressed: _handleAddSong, // Triggers the file picker
                        tooltip: 'Add Song',
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