import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player/pages/playlist_detail_page.dart';
import 'package:music_player/pages/song_detail_page.dart';
import 'package:music_player/ui_components/pick_from_master_view.dart';
import 'package:music_player/utilities/io_print.dart';

import '../ui_components/playback_controls.dart';
import '../ui_components/now_playing_display.dart';
import '../ui_components/song_list.dart';
import '../entities/song.dart';
import '../entities/song_repository.dart';
import '../entities/song_saver.dart';
 
import '../entities/song_controls_manager.dart';

/// State class responsible for invoking the large majority of functions to the user, such as progress bar, play, pause, resume, etc
class PlaylistDetailPageState extends State<PlaylistDetailPage> {
    Song? _currentSong;
    bool _isLoading = true; 
    bool _isLooping = false;
    bool _isReloading = false; // Prevent multiple reloads when invalid file is spotted. 
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
            getCurrentSongList: () => widget.playlist.getCurrentPlaylistSongs(),  // Use callback
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
    /// 
    /// This is significantly more complex than SongScreenState, due to the sub list being built from the master list. 
    /// And there are a ton of weird cases that I fixed after testing. 
    Future<void> _loadAndSynchronizeSongs() async {
        if (!mounted || _isReloading) return; // Prevent multiple rapid reloads
        _isReloading = true;
        setState(() {_isLoading = true;});

        try {
            // First load songs to clean master list
            await SongRepository.loadSongs();
            
            // Clean current playlist of any songs not in master list
            final currentPlaylistSongs = widget.playlist.getCurrentPlaylistSongs();
            final validSongs = currentPlaylistSongs.where((song) {
                return SongRepository.songCollection.any((s) => s.assetPath == song.assetPath);
            }).toList();
            
            // If playlist has invalid songs, update it
            if (validSongs.length != currentPlaylistSongs.length) {
                
                widget.playlist.replaceSongs(validSongs);
                IO.w("Replacement triggered, content of ${widget.playlist.playlistName}:");
                for (Song someSong in widget.playlist.getCurrentPlaylistSongs()){
                    IO.d(someSong.assetPath);
                }
                // Write this update to disk.
                await SongSaver.savePlaylist(
                    playlistName: widget.playlist.playlistName,
                    songs: validSongs
                );    
                // Reload playlists to update SongRepository's map
                await SongRepository.loadPlaylists();
            }
            
            await _controlsManager.synchronizePlaybackState(); 
        } catch (e) {
            IO.e("Error in _loadAndSynchronizeSongs: ", error: e);
        } finally {
            if (mounted) {
                setState(() {
                    _isLoading = false;
                    _isReloading = false;
                });
            } else {
                _isReloading = false;
            }
        }
    }

    /// Let user add a song from a list of currently valid song in the master list. 
    /// 
    /// This create an instance of PickFromMasterView to display the songs on our UI. 
    void _handleAddSong() async {
        await showDialog(
            context: context, 
            builder: (BuildContext context){
                return PickFromMasterView(currentPlaylistName:  widget.playlist.playlistName);
            }
        );
        // Update the song count in the playlist
        widget.playlist.updateSongCount();
        // Trigger a notification to update the PlaylistView
        SongRepository.playlistNotifier.value = Map.from(SongRepository.allSongPlaylists);
        setState(() {/* Rebuild UI */});
    }

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
                title: Text(widget.playlist.playlistName),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.add_to_photos),
                        onPressed: _handleAddSong,
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
                            songs: widget.playlist.getCurrentPlaylistSongs(), 
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