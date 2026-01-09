import 'package:flutter/material.dart';
import 'package:music_player/ui_components/add_song_to_playlists.dart';

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
        // Get the currentSong => always display currentSong.
        final currentSong = widget.controlsManager.currentSong!;

        return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                ),
                actions: [
                    // Add the current song to some playlist(s). 
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addSongToSelectedPlaylists(currentSong),
                        tooltip: "Add To",
                    ),
                    IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () => _showSongMetadata(currentSong),
                        tooltip: "Song Info",
                    ),
                ],
            ),
            body: Stack(
                children:[ 
                    ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height,),
                        child: Column(
                            children: [
                                _updatedSongInfo(),
                                _songProgressBar(context, currentSong),
                            ],
                        ),
                    ),
                    _buildMusicPlayerDock(),
                ]
            ),
        );
    }

    /// Update when a new current song is there. 
    Widget _updatedSongInfo(){
        return ValueListenableBuilder<Song?>(
            valueListenable: widget.controlsManager.currentSongNotifier,
            builder: (context, currentSong, child) {
                return Column(
                    children: [
                        const SizedBox(height: 50),
                        AlbumArt(albumArtBytes: currentSong?.albumArtBytes),
                        _buildSongInfo(context, currentSong),
                    ],
                );
            },
        );
    }
    
    /// Provide display of [_displayedSong.title] and [_displayedSong.artist]
    Widget _buildSongInfo(BuildContext context, Song? song){
        String title; 
        String? artist; 
        if (song == null) {
            title = "Not Playing anything";
            artist = "No Artist Found";
        } else {
            title = song.title;
            artist = song.artist; 
        }
        
        return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        title,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        artist ?? "Unknown Artist",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[100],
                        ),
                    ),
                ],
            ),
        );
    }
    
    /// Special [MusicPlayerDock] configuration. 
    /// 
    /// Not expandable, and not displaying progress bar. 
    /// [MusicPlayerDock] is rebuilt when there are specific changes in order to refresh the progress bar and the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                controlsManager: widget.controlsManager,
                audioService: widget.audioService,
                isDisplayProgressBar: false,
            )
        );
    }

    /// Build progress bar with no title, due to our own bigger title. 
    Widget _songProgressBar(BuildContext context, Song displayedSong) {
        return NowPlayingDisplay(
            controlsManager: widget.controlsManager,
            onSeek: widget.controlsManager.handleSeek,
            showTitle: false,
        );
    }

    /// Let user see the metadata when clicking the info button (top right corner, on the app bar).
    void _showSongMetadata(Song displayedSong) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Song Metadata"),
                content: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            SongMetadataRow(label: "Title", value: displayedSong.title),
                            if (displayedSong.artist != null) SongMetadataRow(label: "Artist", value: displayedSong.artist!),
                            if (displayedSong.album != null) SongMetadataRow(label: "Album", value: displayedSong.album!),
                            SongMetadataRow(label: "Duration", value: MiscFormatter.formatDuration(widget.controlsManager.currentDuration)),
                            SongMetadataRow(label: "File Path", value: displayedSong.assetPath),
                            const SizedBox(height: 16),
                            const Divider(),
                        ],
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                    ),
                ],
            ),
        );
    }

    /// Let user add current song to multiple playlist(s). 
    void _addSongToSelectedPlaylists(Song displayedSong) async {
        await showDialog(
            context: context, 
            builder: (BuildContext context){
                return AddSongToPlaylists(currentSong: displayedSong);
            }
        );

        setState(() {/* Rebuild UI with new song count and new song in playlist */});
    }

    @override
    void dispose() {    
        super.dispose();
    }
}