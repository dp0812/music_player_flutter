import 'package:flutter/material.dart';

import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song_playlist.dart';

/// Display the current list of Song objects. 
/// 
/// This widget is built to be used when user wants to see what the Songs inside some pages. 
/// Highlight the song being play under certain conditions. 
class SongList extends StatelessWidget {
    /// Use for both data display and highlight check. 
    final SongsPlaylist currentPlaylist; 
    final Song? currentSong;
    /// Callback function to play the tapped song.  
    final Function(Song) onSongTap;
    /// Optional callback function for the trailing button. 
    final Function(Song)? onSongButtonTap;

    const SongList({
        super.key,
        required this.currentPlaylist, 
        required this.currentSong,
        required this.onSongTap,
        this.onSongButtonTap
    });

    /// Projects the song list and highlight what song is currently being play. 
    /// 
    /// Highlight is only enable when the song playing originates from BOTH the active playlist and the current playlist. 
    @override
    Widget build(BuildContext context) {
        // The name of the playlist are guaranteed to be unique => use as our identifier. 
        final bool isSamePlaylist = (currentPlaylist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName);
        return ListView.builder(
            itemCount: currentPlaylist.getCurrentPlaylistSongs().length,
            itemBuilder: (context, index) {
                final song = currentPlaylist.getCurrentPlaylistSongs()[index];
                return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(song.artist ?? "Unknown"),
                    onTap: () => onSongTap(song),
                    selected: (song.assetPath == (currentSong?.assetPath)) && isSamePlaylist, // Check for path of the song. 
                    selectedTileColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    trailing: // Button append to the right of the list. 
                        Row(
                            // If not provided the correct function, then we dont display the button.
                            mainAxisSize: MainAxisSize.min,
                            children: [ // The idea is to add more button later on. 
                            if (onSongButtonTap!= null)
                                IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red), 
                                    onPressed: () => onSongButtonTap!(song),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Delete Song", 
                                )
                            ]
                        )
                );
            },
        );
    }
}