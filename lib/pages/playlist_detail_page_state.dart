import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'playlist_detail_page.dart';
import 'song_detail_page.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song.dart';
import '../entities/song_playlist.dart';
import '../entities/song_repository.dart';
import '../entities/song_search_delegate.dart';
import '../ui_components/delete_song.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/pick_from_master_view.dart';
import '../ui_components/reorder_song_list.dart';
import '../ui_components/song_list.dart';

/// Provides a list view of the current songs in the playlist alongside with the playback controls dock and the progress bar.
class PlaylistDetailPageState extends State<PlaylistDetailPage> {

    bool _isLoading = true;
    bool _reorderMode = false;

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
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.playlist.playlistName),
                actions: [
                    // Reorder mode toggle button. 
                    IconButton(
                        icon: Icon(
                        _reorderMode ? Icons.check : Icons.reorder,
                        color: _reorderMode 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : null,
                        ),
                        onPressed: _toggleReorderMode,
                        tooltip: _reorderMode ? "Confirm Order" : "Reorder Songs",
                    ),
                    // Search song button, not available in re order mode.  
                    if (!_reorderMode) IconButton(
                        onPressed: _searchSong,
                        icon: const Icon(Icons.search), 
                    ),
                    // Add song button, not available in re order mode.
                    if (!_reorderMode) IconButton(
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
            )
        );
    }

    /// Lists of current song(s), in normal mode or reorder mode, with bottom padding predefined inside the list. 
    /// 
    /// The song(s) list is rebuilt (may not be rebuilt entirely) when any of these conditions are true: 
    /// 
    /// 1. Changes in the number of song(s), ordering, or corrupted path(s). This is provided by [SongRepository.playlistNotifier] at the current page playlist. Song list is rebuilt entirely, ONCE. 
    /// 2. A new song is set as the active song, and the highlight effect needs to be applied. Note that the article "the" indicates there can be exactly ONE active song. 
    /// Uses [SongControlsManager.currentSongNotifier] and [SongControlsManager.isPlayingNotifier] to render the highlight effect of this active song.
    /// 
    /// Remarks: Under item 2, the song list is rebuilt entirely ONCE, then the highlight effect (rotating disc) is rebuilt exactly ONCE every frame. 
    /// The highlight of the tile on rebuilt ONCE, on the frame that the song list is rebuilt entirely. All list tile(s) are not rebuilt during this rotating disc effect. 
    Widget _buildSongsListWithBottomPadding() {
        return Expanded(
            /// Check for playlist updates is least frequent, => outer most (to not be affected by the changes of the more frequent one). 
            child: ListenableBuilder(
                listenable: SongRepository.playlistNotifier,
                builder: (context, child) {
                    // Check for playlist changes logic - if there are changes in the ordering, or there is a corrupted path, we reset the active list.
                    final SongsPlaylist updatedPlaylist = SongRepository.playlistNotifier.playlists[widget.playlist.playlistName]!;
                    if (!_areSongListsEqual(widget.playlist.getCurrentPlaylistSongs(), updatedPlaylist.getCurrentPlaylistSongs())) {
                        // We swap the song (thus, fail the condition).
                        widget.playlist.replaceSongs(updatedPlaylist.getCurrentPlaylistSongs());
                        // Update active playlist if it's the same.
                        bool isSamePlaylist = widget.playlist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName;
                        if (isSamePlaylist) {
                            widget.controlsManager.setActivePlaylist(updatedPlaylist);
                        }
                    }
                    // End of check for playlist changes logic. 
            
                    /// We only perform the rebuild of the song list based on the [currentSongNotifier] and [isPlayingNotifier] (to display the leading overlay selected effect). 
                    return ValueListenableBuilder<Song?>(
                        valueListenable: widget.controlsManager.currentSongNotifier,
                        builder: (context, currentSong, child) {
                            return ValueListenableBuilder<bool>(
                                valueListenable: widget.controlsManager.isPlayingNotifier,
                                builder: (context, isPlaying, child) {
                                    // If reorder, use the special re orderable list.  
                                    if (_reorderMode) {
                                        return ReorderableSongList(
                                            currentSong: currentSong,
                                            currentPlaylist: widget.playlist, 
                                            controlsManager: widget.controlsManager, 
                                            onSongsReordered: (newSongs){
                                                setState(() {
                                                    widget.playlist.replaceSongs(newSongs);
                                                });
                                            },
                                            isPlaying: isPlaying,
                                        );
                                    } 
                                    
                                    // Normal song list.
                                    return SongList(
                                        currentPlaylist: widget.playlist,
                                        currentSong: currentSong,
                                        onSongTap: _handleSongTap,
                                        onSongButtonTap: _handleSongButtonTap, 
                                        isPlaying: isPlaying,
                                    );
                                }
                            );
                        }
                    );
                },
            ),
        );
    }

    /// Normal [MusicPlayerDock] configuration. 
    /// 
    /// Expandable, default in compact mode, showing the title. 
    /// [MusicPlayerDock] is rebuilt when there are specific changes in order to refresh the progress bar and the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                controlsManager: widget.controlsManager,
                audioService: widget.audioService,
            )
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

    // Update reorder mode.
    void _toggleReorderMode() {
        setState(() =>_reorderMode = !_reorderMode);
        if (_reorderMode) HapticFeedback.mediumImpact();
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
    
    /// Load available songs using [SongRepository.loadPlaylist] and synchronize playback state. 
    /// 
    /// Remove any invalid songs spotted. 
    /// Remarks: The loading is done more frequently to reflect the changes user make during re order mode. 
    /// By more, I mean everytime there is a change.   
    Future<void> _loadAndSynchronizeSongs() async {
        setState(() => _isLoading = true);

        /// I no longer do the following code: 
        /// await SongRepository.loadSongs();
        /// This is due to the loading time it takes for this loadSongs to work, thus, making an irritatingly long progress indicator for a playlist. 
        await SongRepository.loadPlaylist(playlistName: widget.playlist.playlistName);

        // Get the updated playlist from repository
        final updatedPlaylist = SongRepository.playlistNotifier.playlists[widget.playlist.playlistName];
        if (updatedPlaylist != null) {
            setState(() {
                widget.playlist.replaceSongs(updatedPlaylist.getCurrentPlaylistSongs());
            });
        }

        // Synchronize playback state with the shared controls manager.
        await widget.controlsManager.synchronizePlaybackState(widget.playlist);
        setState(() => _isLoading = false);
    }
    
    /// Check both the length and the content. 
    /// 
    /// Remarks: This is different from the last version due to the reorder feature. 
    /// Since reordering does not change the total number of song, we need to check each Song in the list, WITH the ordering exactly as they are. 
    /// If we spot a different, we know that some reordering has been done. 
    bool _areSongListsEqual(List<Song> list1, List<Song> list2) {
        if (list1.length != list2.length) return false;
        for (int i = 0; i < list1.length; i++) {
            if (!list1[i].isEqual(list2[i])) return false; 
        }
        return true;
    }

    @override
    void dispose() {
        super.dispose();
    }
}