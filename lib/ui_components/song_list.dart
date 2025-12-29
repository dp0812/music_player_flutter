import 'package:flutter/material.dart';
import 'package:music_player/ui_components/album_art.dart';

import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song_playlist.dart';
import 'custom_list_tile.dart';

/// Display the current list of Song objects. 
/// 
/// This widget is built to be used when user wants to see what the Songs inside some pages. 
/// Highlight the song being play under certain conditions. 
/// Include a bottom padding just enough for the dock in compact mode when scroll to the bottom of the list. 
class SongList extends StatelessWidget {
    /// Use for both data display and highlight check. 
    final SongsPlaylist currentPlaylist; 
    final Song? currentSong;
    /// Callback function to play the tapped song.  
    final Function(Song) onSongTap;
    /// Optional callback function for the trailing button. 
    final Function(Song)? onSongButtonTap;
    /// Avoid dock (in compact mode) from preventing user click on the last item of the list. 
    final double bottomPadding; 

    const SongList({
        super.key,
        required this.currentPlaylist, 
        required this.currentSong,
        required this.onSongTap,
        this.onSongButtonTap,
        this.bottomPadding = 180,
    });

    /// Projects the song list and highlight what song is currently being play. 
    /// 
    /// Highlight is only enable when the song playing originates from BOTH the active playlist and the current playlist. 
    @override
    Widget build(BuildContext context) {
        return currentPlaylist.getCurrentPlaylistSongs().isEmpty 
            ? _placeholderIfNoSongFound()
            : _songsList(context);
    }

    Widget _songsList(BuildContext context){
        // The name of the playlist are guaranteed to be unique => use as our identifier. 
        final bool isSamePlaylist = (currentPlaylist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName);
        return CustomScrollView(
            slivers: [
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        childCount: currentPlaylist.getCurrentPlaylistSongs().length,
                        (context, index){
                            final song = currentPlaylist.getCurrentPlaylistSongs()[index];
                            bool isSelected = (song.assetPath == (currentSong?.assetPath)) && isSamePlaylist;
                            return _customListTile(song,isSelected);  
                        }
                    ) 
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + bottomPadding)),
            ],
        );
    }

    Widget _placeholderIfNoSongFound(){
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    "No songs found. Click the 'Add Songs' button to create one!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                ),
            ),
        );
    }

    Widget _customListTile(Song song, bool isSelected){
        return CustomListTile(
            leading: AlbumArt(albumArtBytes: song.albumArtBytes, artWidth: 30, artHeight: 30,),
            title: song.title,
            subtitle: song.artist ?? "Unknown",
            onTap: () => onSongTap(song),
            selected: isSelected,
            alpha: 0.09,
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
    }
}