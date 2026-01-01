import 'dart:async';
import 'package:flutter/material.dart';

import 'playlist_detail_page.dart';
import 'song_detail_page.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song.dart';
import '../entities/song_playlist.dart';
import '../entities/song_repository.dart';
import '../entities/song_search_delegate.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/song_list.dart';
import '../ui_components/delete_song.dart';
import '../ui_components/pick_from_master_view.dart';

/// Provides a list view of the current songs in the playlist alongside with the playback controls dock and the progress bar.
class PlaylistDetailPageState extends State<PlaylistDetailPage> {

    // Load flag for UI purpose. 
    bool _isLoading = true;

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
                            // Search song button. 
                            IconButton(
                                onPressed: _searchSong,
                                icon: const Icon(Icons.search), 
                            ),
                            // Add song button. 
                            IconButton(
                                icon: const Icon(Icons.add_to_photos),
                                onPressed: _handleAddSong,
                                tooltip: "Add Song",
                            ),
                        ],
                    ),
                    body: Stack(
                        children: [
                            Column(
                                children: [
                                    _buildSongsListWithBottomPadding(),
                                ],
                            ),
                            _buildMusicPlayerDock(),
                        ],
                    ),
                );
            },
        );
    }

    /// Lists of current song(s), with bottom padding predefined inside the list. 
    /// 
    /// This padding (180) is just enough for the dock in compact mode if scroll to list bottom.
    Widget _buildSongsListWithBottomPadding(){
        return Expanded(
            child: Scaffold(
                // Allow the inner song list to be rebuild if there is a corrupted path. 
                body: AnimatedBuilder(
                    animation: SongRepository.playlistNotifier, 
                    builder: (context, child){
                        final SongsPlaylist updatedPlaylist = SongRepository.playlistNotifier.playlists[widget.playlist.playlistName]!;
                        // If there is a corrupted path, we reset the active playlist. 
                        if (updatedPlaylist.getCurrentPlaylistSongs().length != widget.playlist.getCurrentPlaylistSongs().length){
                            widget.playlist.replaceSongs(updatedPlaylist.getCurrentPlaylistSongs());  // We swap the song (thus, fail the condition). 
                            widget.controlsManager.setActivePlaylist(updatedPlaylist);  // Using only this work, but doing this every single build is ineffective. 
                        }
                        return SongList( 
                            currentPlaylist: widget.playlist,
                            currentSong: widget.controlsManager.currentSong,
                            onSongTap: _handleSongTap,
                            onSongButtonTap: _handleSongButtonTap, 
                            isPlaying: widget.controlsManager.audioService.isPlaying,
                        );
                    }
                ),
            )
        );
    }

    /// Normal [MusicPlayerDock] configuration. 
    /// 
    /// Expandable, default in compact mode, showing the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                currentSong: widget.controlsManager.currentSong,
                duration: widget.controlsManager.currentDuration,
                position: widget.controlsManager.currentPosition,
                onSeek: widget.controlsManager.handleSeek,
                pushToDetail: widget.controlsManager.pushToSongDetailPage,
                
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

    /// Search the list of song, to interact with the song searched, one at a time. 
    void _searchSong(){
        showSearch(
            context: context, 
            delegate: SongSearchDelegate(
                availableSongs: widget.playlist.getCurrentPlaylistSongs(),
                onSongTap: _handleSongTap),
        );
    }

    /// Load available songs and synchronize playback state. 
    /// 
    /// Remove any invalid songs spotted. 
    Future<void> _loadAndSynchronizeSongs() async {
        setState(() => _isLoading = true);

        await SongRepository.loadSongs();
        
        final currentPlaylistSongs = widget.playlist.getCurrentPlaylistSongs();
        final validSongs = commonValidSongs(currentPlaylistSongs);
        
        // If playlist has invalid songs, only reload the playlist that is invalid.
        if (validSongs.length != currentPlaylistSongs.length) { 
            await SongRepository.loadPlaylist(playlistName: widget.playlist.playlistName);
        }
        
        // Synchronize playback state with the shared controls manager
        await widget.controlsManager.synchronizePlaybackState(widget.playlist);
        setState(() => _isLoading = false);
    }
    
    /// Return the common Song(s) between the [currentPlaylistSongs] and the [masterSongPlaylist].
    /// 
    /// These common Song(s) are Song object(s) from the masterSongPlaylist, not from the currentPlaylistSongs.  
    /// The order is not important, as we are only trying to see if there are invalid songs or not. 
    List<Song> commonValidSongs(List<Song> currentPlaylistSongs){
        if (currentPlaylistSongs.isEmpty || SongRepository.masterSongPlaylist.getCurrentPlaylistSongs().isEmpty) return [];
        final Set<String> assetPathSet = currentPlaylistSongs.map((song) => song.assetPath).toSet();        
        return SongRepository.masterSongPlaylist.getCurrentPlaylistSongs()
            .where((song) => assetPathSet.contains(song.assetPath))
            .toList();
    }

    @override
    void dispose() {
        super.dispose();
    }
}