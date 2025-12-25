import 'package:flutter/material.dart';

import 'song_detail_page.dart';
import '../entities/song.dart';
import '../ui_components/album_art.dart';
import '../ui_components/now_playing_display.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/song_meta_data_row.dart';
import '../utilities/misc_formatter.dart'; 

/// Provides metatdata access of song, and has an exclusive progress bar. 
/// 
/// This follows the current song playing. 
/// That is, if the current song playing becomes another song, this screen will update accordingly. 
class SongDetailPageState extends State<SongDetailPage> {
    
    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        // Rebuild when controlsManager changes.
        return ListenableBuilder(
            listenable: widget.controlsManager,
            builder: (context, child) {
                // Get the currentSong => always display currentSong.
                final currentSong = widget.controlsManager.currentSong ?? widget.initialSong;
                final isPlaying = widget.audioService.isPlaying;
                final isSongEnded = widget.controlsManager.songEnded && 
                                   (widget.controlsManager.currentSong?.assetPath == currentSong.assetPath);
                final displayedSong = widget.controlsManager.currentSong ?? widget.initialSong;

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
                                onPressed: () => _showSongMetadata(displayedSong),
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
                                AlbumArt(albumArtBytes: displayedSong.albumArtBytes),
                                // Song Info Section.
                                _buildSongInfo(context, displayedSong),
                                // Progress Bar Section
                                _buildProgressBar(context, displayedSong, isSongEnded, isPlaying),
                                Spacer(),
                            ],
                        ),
                    ),
                    // The bottom music player dock, include progress bar, title and buttons for next/previous, pause/play/resume, loop/random.
                    bottomNavigationBar: MusicPlayerDock(
                        isDisplayProgressBar: false,
                        currentSong: widget.controlsManager.currentSong ?? displayedSong,
                        duration: widget.controlsManager.currentDuration,
                        position: widget.controlsManager.currentPosition,
                        onSeek: widget.controlsManager.handleSeek,

                        audioService: widget.audioService,
                        onPreviousSong: widget.controlsManager.gotoPreviousSong,
                        onNextSong: widget.controlsManager.gotoNextSong,
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
    
    /// Provide display of [_displayedSong.title] and [_displayedSong.artist]
    Widget _buildSongInfo(BuildContext context, Song song){
        return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        song.title,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                        song.artist ?? "Unknown Artist",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[100],
                        ),
                    ),
                ],
            ),
        );
    }

    /// Build progress bar with no title, due to our own bigger title. 
    Widget _buildProgressBar(BuildContext context, Song displayedSong, bool isSongEnded, bool isPlaying) {
        return NowPlayingDisplay(
            currentSong: displayedSong, 
            duration: widget.controlsManager.currentDuration, 
            position: widget.controlsManager.currentPosition, 
            onSeek: widget.controlsManager.handleSeek,
            showTitle: false,
        );
    }

    /// Let user see the metadata when clicking the info button (top right corner, on the app bar).
    void _showSongMetadata(Song displayedSong) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text("Song Metadata"),
                content: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            _buildMetadataRow("Title", displayedSong.title),
                            if (displayedSong.artist != null) _buildMetadataRow("Artist", displayedSong.artist!),
                            if (displayedSong.album != null) _buildMetadataRow("Album", displayedSong.album!),
                            _buildMetadataRow("Duration", MiscFormatter.formatDuration(widget.controlsManager.currentDuration)),
                            _buildMetadataRow("File Path", displayedSong.assetPath),
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

    @override
    void dispose() {    
        super.dispose();
    }
}