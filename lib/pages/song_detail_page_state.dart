import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player/pages/song_detail_page.dart';
import 'package:music_player/ui_components/album_art.dart';
import 'package:music_player/ui_components/playback_controls.dart';
import 'package:music_player/ui_components/song_detail_progress_bar.dart';
import 'package:music_player/ui_components/song_meta_data_row.dart';
import 'package:music_player/utilities/io_print.dart';
import 'package:music_player/utilities/misc_formatter.dart'; 

import '../entities/song.dart';

/// Provides metadata details of the song and other things. 
/// 
/// Refactored to use the unified playback_controls.dart
///  
/// 1. Remarks A: UI of this class updates based on listener => must use notify in business logic for this class to work.  
/// 2. Remakrs B: Metadata read is currently very inefficient. 
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

        // Sync data as usual. 
        _loadCurrentPlaybackInfo();
        _setupListeners();
    }

    @override
    Widget build(BuildContext context) {
        // To avoid the pixel overflow in the bottom:
        // set resizeToAvoidBottomInset = false and wrap the body in SingleChildScrollView with ConstrainedBox 
        return Scaffold(
            resizeToAvoidBottomInset: false,
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
            body: SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                        children: [
                            // Album Art Section 
                            Spacer(),
                            AlbumArt(albumArtBytes: _displayedSong.albumArtBytes),
                            // Song Info Section.
                            _buildSongInfo(context),
                            // Progress Bar Section
                            _buildProgressBar(context),
                            Spacer(),
                        ],
                    ),
                ),
            ),
            bottomNavigationBar: PlaybackControls(
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

    /// Provide display of [_displayedSong.title] and [_displaySong.artist]
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

    void _showSongMetadata() {
        // Show dialog with song metadata
        IO.d("Song data in Meta data: ");
        IO.t("Song title: ${_displayedSong.title} ");
        IO.t("Song artist: ${_displayedSong.artist} ");
        IO.t("Song album: ${_displayedSong.album} ");
        IO.t("Song filePath: ${_displayedSong.assetPath} ");
        
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
    /// 
    /// This parent widget, currently, should be either PlaylistDetailPageState or SongScreenState
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
    /// The only update that come directly from audioService is [onDurationChanged] - the total time length of a Song 
    /// The user cannot affect this attribute by any of the buttons provided. 
    void _setupListeners() {
        // Listen to position updates
        _positionSubscription = widget.controlsManager.onPositionChanged.listen((position) {
            if (mounted) {
                setState(() {
                    _currentPosition = position;
                    // Check if we're at the end of the song
                    if (_isSongEnded()) {
                        _songEnded = true;
                    } else {
                        _songEnded = false;
                    }
                });
            }
        });

        // Listen to duration updates
        _durationSubscription = widget.audioService.onDurationChanged.listen((duration) {
            if (mounted) {
                setState(() {_currentDuration = duration;});
            }
        });

        // Listen to current song updates
        _currentSongSubscription = widget.controlsManager.onCurrentSongChanged.listen((song) {
            if (song != null && mounted) {
                setState(() {
                    _displayedSong = song;  // Always update displayed song to match playing song!
                    _songEnded = false;     // Reset when song changes
                });
            }
        });

        _loopSubscription = widget.controlsManager.onLoopChanged.listen((isLooping) {
            if (mounted) {
                setState(() {
                    _isLooping = isLooping;
                });
            }
        });

        _randomSubscription = widget.controlsManager.onRandomChanged.listen((isRandom){
            if (mounted){
                setState(() {
                    _isRandom = isRandom; 
                });
            }
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

    @override
    void dispose() {
        _positionSubscription?.cancel();
        _durationSubscription?.cancel();
        _currentSongSubscription?.cancel();
        _loopSubscription?.cancel();
        _randomSubscription?.cancel();
        super.dispose();
    }
}