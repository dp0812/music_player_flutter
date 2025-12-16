import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player/pages/song_detail_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_player/ui_components/album_art.dart';
import 'package:music_player/ui_components/smart_play_button.dart';
import 'package:music_player/ui_components/song_detail_progress_bar.dart';
import 'package:music_player/ui_components/song_meta_data_row.dart';
import 'package:music_player/utilities/io_print.dart';
import 'package:music_player/utilities/misc_formatter.dart'; 

import '../entities/song.dart';

class SongDetailPageState extends State<SongDetailPage> {
    late Song _displayedSong;
    late Duration _currentPosition;
    late Duration _currentDuration;
    Song? _currentlyPlayingSong;
    StreamSubscription<Duration>? _positionSubscription;
    StreamSubscription<Duration>? _durationSubscription;
    StreamSubscription<Song?>? _currentSongSubscription;
    StreamSubscription<PlayerState>? _playerStateSubscription; 
    /// Flag to track the state of the song playing
    bool _songEnded = false;
    
    @override
    void initState() {
        super.initState();
        _displayedSong = widget.initialSong;
        _currentlyPlayingSong = widget.controlsManager.getCurrentSong();
        
        // Set initial position from parent widget. 
        _currentPosition = widget.initialPosition;
        _currentDuration = widget.initialDuration;
        
        // Check if song has ended based on passed data
        if (_currentDuration > Duration.zero) {
            if (_isSongNearEnd()) {
                _songEnded = true;
            }
        }

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
                            // Smart Button Section
                            Padding(
                                padding: EdgeInsets.only(bottom: 80),
                                child: Center(
                                child: _buildSmartPlayButton(context),
                                ),
                            ),
                        ],
                    ),
                ),
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
        return SongDetailProgressBar(
            displayedSong: _displayedSong,
            currentDuration: _currentDuration,
            currentPosition: _currentPosition,
            onSeek: _handleSeek,
            isDisplayedSongPlaying: _isDisplayedSongPlaying,
            songEnded: _songEnded,
            activeColor: _songEnded ? Colors.grey : Theme.of(context).colorScheme.primary,
            inactiveColor: _songEnded ? Colors.grey[200] : Theme.of(context).colorScheme.secondary,

            nowPlayingColorDetail: Colors.deepPurple[600]!,
            nowPlayingColorText: Colors.deepPurple[600]!,
            nowPlayingColorBackground: Colors.deepPurple[50]!,
        );
    }

    Widget _buildSmartPlayButton(BuildContext context) {
        return SmartPlayButton(
            isAudioPlaying: widget.audioService.isPlaying, 
            onPlayPause: _handlePlayPause,
            buttonColor: Theme.of(context).colorScheme.primary,
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
                        if (_currentlyPlayingSong != null) _buildMetadataRow("Now Playing", _currentlyPlayingSong!.title),
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
    void _setupListeners() {
        // Listen to position updates
        _positionSubscription = widget.audioService.onPositionChanged.listen((position) {
            if (mounted) {
                setState(() {
                    _currentPosition = position;
                    // Check if we're at the end of the song
                    if (_isSongNearEnd() ) {
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
                    _currentlyPlayingSong = song;
                    _displayedSong = song;  // Always update displayed song to match playing song!
                    _songEnded = false; // Reset when song changes
                });
            }
        });

         // Listen to player state updates
        _playerStateSubscription = widget.audioService.audioPlayer.onPlayerStateChanged.listen((state) {
            if (mounted) {
                if (state == PlayerState.completed && _isDisplayedSongPlaying) {
                    setState(() {
                        _songEnded = true;
                        _currentPosition = Duration.zero; // Force reset UI
                    });
                } else if (state == PlayerState.playing) {
                    _songEnded = false;
                }
            }
        });
    }

    /// Let user change position based on the progress bar. 
    /// 
    /// Remarks: [_sondEnded] is the guard condition to allow seeking when songs "ended".
    /// This ended condition is enable if we are in the last several ms of the song. 
    void _handleSeek(double value) async {
        final newPosition = Duration(milliseconds: value.round());
        if (!_songEnded){ // Song has not end - you can change position. 
            widget.audioService.seek(newPosition);
            _songEnded = false; // Reset ended flag when user seeks
            return;
        }

        // Otherwise, song ends, we should replay this song. 
        _songEnded = false;    
        // Start playing the song
        widget.controlsManager.playSelectedSong(_displayedSong);  
        // A reasonable delay is 10ms for my machine, but who knows what other machine do...
        await Future.delayed(Duration(milliseconds: 50));
        widget.audioService.seek(newPosition);
        // Update UI immediately
        if (mounted) {
            setState(() {_currentPosition = newPosition;});
        }
    }

    /// If there is a song playing => pause. If no song playing => reset to start
    /// 
    /// There are very significant changes of end condition compare to the normal [handlePlayResumePause] of SongControlsManager.
    void _handlePlayPause() {
        if (widget.audioService.isPlaying) {
            widget.audioService.pause();
            return;
        }
        
        if (_isSongNearEnd() || _songEnded) { 
            // restart - prevent the bar from crashing into the stop and lost the audio stream.  
            _songEnded = false;
            widget.controlsManager.playSelectedSong(_displayedSong);
        } else {
            widget.audioService.resume();
        }
    }

    /// Check if the [_currentlyPlayingSong] is the same as [_displayedSong]
    bool get _isDisplayedSongPlaying {
        return _currentlyPlayingSong?.assetPath == _displayedSong.assetPath;
    }

    /// Song is considered end if [toSkip] ms away from the end and widget.audioService.isPlaying is false. 
    /// 
    /// Last [toSkip] ms is considered end of the song due to technical reason. Default to 50 ms.  
    /// Checking !widget.audioService.isPlaying is to prevent a 1 problematic frame in the transition from 1 song detail to the other in Loop mode. 
    /// This 1 frame flash a slight, but noticeable moment of the orange box - song ended, press play or drag to replay.
    /// 
    /// Currently I cannot find out a consistent way to ensure the following WITHOUT the [toSkip] duration: 
    /// 
    /// When loop mode is OFF, and the song comes to an end in the song detail page state, the 2 following condition MUST be sastify: 
    /// 
    /// a. It should revert the progress bar to the beginning, and clicking play again should be seamless. That is, it should not have any visual problems, and/or audio problem.
    /// 
    /// b. Clicking on the play pause ensure that the app is correctly continuing (if pause midway). 
    bool _isSongNearEnd({int toSkip = 50}){
        return 
        (_currentDuration > Duration.zero)
        && (_currentPosition.inMilliseconds >= _currentDuration.inMilliseconds - toSkip)
        && !widget.audioService.isPlaying; 
    }

    @override
    void dispose() {
        _positionSubscription?.cancel();
        _durationSubscription?.cancel();
        _currentSongSubscription?.cancel();
        _playerStateSubscription?.cancel(); 
        super.dispose();
    }
}