import 'dart:async';
import 'package:flutter/material.dart';

import 'song_detail_page.dart';
import '../entities/song.dart';
import '../ui_components/album_art.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/song_detail_progress_bar.dart';
import '../ui_components/song_meta_data_row.dart';
import '../utilities/misc_formatter.dart'; 

/// Provides metatdata access of song, and has an exclusive progress bar. 
class SongDetailPageState extends State<SongDetailPage> {
    late Song _displayedSong;
    late Duration _currentPosition;
    late Duration _currentDuration;
    bool _isLooping = false;
    bool _songEnded = false; 
    bool _isRandom = false; 

    StreamSubscription<Duration>? _positionSubscription;
    StreamSubscription<Duration>? _durationSubscription;
    StreamSubscription<Song?>? _currentSongSubscription;
    StreamSubscription<bool>? _loopSubscription;
    StreamSubscription<bool>? _randomSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;
    
    @override
    void initState() {
        super.initState();
        _displayedSong = widget.initialSong;

        // Set initial position from parent widget. 
        _currentPosition = widget.initialPosition;
        _currentDuration = widget.initialDuration;
        _isLooping = widget.controlsManager.getIsLooping();
        _isRandom = widget.controlsManager.getIsRandom();

        // Check if song has ended based on passed data
        if (_isSongEnded()) _songEnded = true;

        _setupListeners();
        _setupPlayerCompletionListener();
        _loadCurrentPlaybackInfo();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            resizeToAvoidBottomInset: false,
            // Purely for the 2 buttons (go back and info)
            appBar: AppBar(
                leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                ),
                actions: [
                    IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: _showSongMetadata,
                        tooltip: "Song Info",
                    ),
                ],
            ),
            body: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                        children: [
                            // Album Art Section 
                            SizedBox(height: 50),
                            AlbumArt(albumArtBytes: _displayedSong.albumArtBytes),
                            // Song Info Section.
                            _buildSongInfo(context),
                            // Progress Bar Section
                            _buildProgressBar(context),
                            Spacer(),
                        ],
                    ),
                ),
            // The bottom music player dock, include progress bar, title and buttons for next/previous, pause/play/resume, loop/random.
            bottomNavigationBar: MusicPlayerDock(
                isDisplayProgressBar: false,
                currentSong: _displayedSong,
                duration: _currentDuration,
                position: _currentPosition,
                onSeek: _handleSeek,

                audioService: widget.audioService,
                onPreviousSong: widget.controlsManager.gotoPreviousSong,
                onNextSong: widget.controlsManager.gotoNextSong,
                onPlayPauseResume: widget.controlsManager.handlePlayResumePause,
                onStop: widget.controlsManager.stop,
                onToggleLoop: widget.controlsManager.toggleLoop,
                isLooping: _isLooping,
                onToggleRandom: widget.controlsManager.toggleRandom,
                isRandom: _isRandom,
            ),
        );
    }

    /// Provide display of [_displayedSong.title] and [_displayedSong.artist]
    Widget _buildSongInfo(BuildContext context){
        return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        _displayedSong.title,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                        _displayedSong.artist ?? "Unknown Artist",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[100],
                        ),
                    ),
                ],
            ),
        );
    }

    /// Build the progress bar, based on the current colorScheme of Theme. 
    Widget _buildProgressBar(BuildContext context) {
        final isPlaying = widget.audioService.isPlaying;
        final isCurrentSong = widget.controlsManager.getCurrentSong()?.assetPath == _displayedSong.assetPath;
        final isSongEnded = _songEnded || (!isPlaying && _isSongEnded());

        return SongDetailProgressBar(
            displayedSong: _displayedSong,
            currentDuration: _currentDuration,
            currentPosition: isSongEnded ? Duration.zero : _currentPosition,
            onSeek: _handleSeek,
            isDisplayedSongPlaying: isCurrentSong && isPlaying,
            songEnded: isSongEnded, 
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.secondary,
            nowPlayingColorDetail: Colors.deepPurple[600]!,
            nowPlayingColorText: Colors.deepPurple[600]!,
            nowPlayingColorBackground: Colors.deepPurple[50]!,
        );
    }

    /// Let user see the metadata when clicking the info button (top right corner, on the app bar).
    void _showSongMetadata() {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text("Song Metadata"),
                content: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        _buildMetadataRow("Title", _displayedSong.title),
                        if (_displayedSong.artist != null) _buildMetadataRow("Artist", _displayedSong.artist!),
                        if (_displayedSong.album != null) _buildMetadataRow("Album", _displayedSong.album!),
                        _buildMetadataRow("Duration", MiscFormatter.formatDuration(_currentDuration)),
                        _buildMetadataRow("File Path", _displayedSong.assetPath),
                        SizedBox(height: 16),
                        Divider(),
                    ],
                ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Close"),
                    ),
                ],
            ),
        );
    }

    Widget _buildMetadataRow(String label, String value) {
        return SongMetadataRow(label: label, value: value);
    }

    /// Get current Position (from the previous - parent widget). 
    void _loadCurrentPlaybackInfo() async {
        final position = await widget.audioService.getCurrentPosition();
        final duration = await widget.audioService.getCurrentDuration();
        
        if (mounted) {
            setState(() {
                _currentPosition = position ?? Duration.zero;
                _currentDuration = duration ?? Duration.zero;
            });
        }
    }

    /// Listen to changes in the position of the song, and reset UI accordingly. 
    /// 
    /// The only update that come directly from audioService is [onDurationChanged] - the total time length of a Song.
    /// The user cannot affect this attribute by any of the buttons provided. 
    void _setupListeners() {
        // Progress bar position changes.
        _positionSubscription = widget.controlsManager.onPositionChanged.listen((position) {
            if (mounted) {
                setState(() {
                    _currentPosition = position;
                    _songEnded = _isSongEnded();
                });
            }
        });

        // Progress bar total duration changes.
        _durationSubscription = widget.audioService.onDurationChanged.listen((duration) {
            if (mounted) setState(() => _currentDuration = duration);
        });

        // Current song changes.
        _currentSongSubscription = widget.controlsManager.onCurrentSongChanged.listen((song) {
            if (song != null && mounted) {
                setState(() {
                    _displayedSong = song;  // Always update displayed song to match playing song!
                    _songEnded = false;     // Reset when song changes
                });
            }
        });

        // Loop mode changes.
        _loopSubscription = widget.controlsManager.onLoopChanged.listen((isLooping) {
            if (mounted) setState(() => _isLooping = isLooping);
        });

        // Random mode changes.
        _randomSubscription = widget.controlsManager.onRandomChanged.listen((isRandom){
            if (mounted) setState(() =>_isRandom = isRandom);
        });
    }

    /// Let user change position based on the progress bar. 
    void _handleSeek(double value) async {
        widget.controlsManager.handleSeek(value);
        _songEnded = false; // Reset when user seeks
    } 

    bool _isSongEnded() {
        return widget.controlsManager.getSongEnded;
    }

    /// Completion listener of THIS page. 
    void _setupPlayerCompletionListener() {
        // current 
        _playerCompleteSubscription = widget.audioService.audioPlayer.onPlayerComplete.listen((_) {
            widget.controlsManager.handleSongCompletion();
        });
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