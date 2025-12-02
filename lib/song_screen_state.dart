import 'package:flutter/material.dart';

import 'ui_components/playback_controls.dart';
import 'ui_components/now_playing_display.dart';
import 'ui_components/song_list.dart';
import 'entities/song.dart';
import 'song_data.dart';

import 'song_screen.dart'; // Import the parent widget

/// State class made public due to the fact that I can not read long file. 
class SongScreenState extends State<SongScreen> {
    Song? _currentSong;
    bool _isLoading = true; 

    @override
    void initState() {
        super.initState();
        _loadSongs();
    }

    @override
    void dispose() {
        widget.audioService.dispose();
        super.dispose();
    }

    Future<void> _loadSongs() async {
        await SongData.loadSongsFromFiles();
        setState(() {
            _isLoading = false;
        });
    }
    /// Change the button UI if clicked, based on the state of the audioService. 
    void _handlePlayResumePause() {
        final audioService = widget.audioService;
        
        if (audioService.isPlaying) {
            audioService.pause();
        } else if (audioService.isPaused) {
            audioService.resume();
        } else {
            // If the whole app is stopped, and user click run, play the 1st song in the list. 
            if (_currentSong == null && SongData.availableSongs.isNotEmpty) { 
                setState(() {
                    _currentSong = SongData.availableSongs.first;
                });
                audioService.playFile(_currentSong!.assetPath);
            }
        }
        setState(() {});
    }
    
    /// Clear the selection of song (meaning, no song will be play) 
    void _handleStop() {
        widget.audioService.stop();
        setState(() {
            _currentSong = null;
        });
    }

    @override
    Widget build (BuildContext context){
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            appBar: AppBar(title: const Text('MP3 Player Test Version')),
            body: Column(
                children: [
                    NowPlayingDisplay(currentSong: _currentSong),
                    Expanded(
                        child: SongList(
                            songs: SongData.availableSongs, 
                            currentSong: _currentSong,
                            onSongTap: (song) {
                                setState(() {
                                    _currentSong = song;
                                });
                                widget.audioService.playFile(song.assetPath);
                            },
                        ),
                    ),
                ],
            ),
            bottomNavigationBar: PlaybackControls(
                audioService: widget.audioService,
                onPlayPauseResume: _handlePlayResumePause,
                onStop: _handleStop,
            ),
        );
    }
}