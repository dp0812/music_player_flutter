import 'dart:async';
import 'package:flutter/material.dart';

import 'playlist_detail_page.dart';
import 'song_detail_page.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song.dart';
import '../entities/song_repository.dart';
import '../entities/song_saver.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/song_list.dart';
import '../ui_components/delete_song.dart';
import '../ui_components/pick_from_master_view.dart';
import '../utilities/io_print.dart';

/// Provides a list view of the current songs in the playlist alongside with the playback controls dock and the progress bar.
class PlaylistDetailPageState extends State<PlaylistDetailPage> {

    // Load flag for UI purpose. 
    bool _isLoading = true;
    bool _isReloading = false;

    @override
    void initState() {
        super.initState();
        // Ensure intergrity of the playlist when we go to this page. 
        _loadAndSynchronizeSongs();
    }

     @override
    Widget build(BuildContext context){
        // Placeholder loading screen. 
        if (_isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        // Rebuild when controlsManager changes.
        return ListenableBuilder(
            listenable: widget.controlsManager,
            builder: (context, child) {
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
                            // List of all current Song(s).
                            Expanded(
                                child: SongList(
                                    currentPlaylist: widget.playlist,
                                    currentSong: widget.controlsManager.currentSong,
                                    onSongTap: _handleSongTap,
                                    onSongButtonTap: _handleSongButtonTap, 
                                ),
                            ),
                        ],
                    ),
                    // The bottom music player dock, include progress bar, title and buttons for next/previous, pause/play/resume, loop/random.
                    bottomNavigationBar: MusicPlayerDock(
                        currentSong: widget.controlsManager.currentSong,
                        duration: widget.controlsManager.currentDuration,
                        position: widget.controlsManager.currentPosition,
                        onSeek: widget.controlsManager.handleSeek,
                        
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
            },
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
                    return FadeTransition(
                        opacity: animation,
                        child: child,
                    );
                },
            ),
        );
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

        widget.playlist.updateSongCount();
        setState(() {/* Rebuild UI with new song count and new song in playlist */});
    }

    /// If not currently playing => play the song. If currently playing => go to Song detail page.
    /// 
    /// Check of currently playing song is done using the assetPath in the system.   
    void _handleSongTap(Song song) {
        // Check if this is the currently playing song
        final bool isSamePlaylist = widget.playlist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName;  
        if (widget.controlsManager.currentSong?.assetPath == song.assetPath && widget.audioService.isPlaying && isSamePlaylist) {
            _goToSongDetailPage(song);
            return;
        } 
        
        // Otherwise => play this song and set active list = current widget.playlist
        widget.controlsManager.playSelectedSong(song, widget.playlist);
        
    }

    /// Deleting a song from a playlist.
    /// 
    /// Only remove said song from the current playlist, not from the [SongRepository.masterSongPlaylist]. 
    void _handleSongButtonTap(Song song) async {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
                return DeleteSong(playlistName: widget.playlist.playlistName, someSong: song);
            },
        );

        widget.playlist.updateSongCount();
        setState(() {/* Rebuild UI */});
    }

    /// Load available songs and synchronize playback state. 
    /// 
    /// This is significantly more complex than SongScreenState, due to the sub list being built from the master list. 
    /// The sad fact of this version is that for this to trigger, one need to go back to the playlist detail page again. 
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
                return SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().any((s) => s.assetPath == song.assetPath);
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
            
            // Synchronize playback state with the shared controls manager
            await widget.controlsManager.synchronizePlaybackState(widget.playlist);
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

    @override
    void dispose() {
        super.dispose();
    }
}