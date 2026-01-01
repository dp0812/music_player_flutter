import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'album_art.dart';
import 'custom_list_tile.dart';
import 'rotating_disc.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song_playlist.dart';

/// Display the current list of Song objects. 
/// 
/// This widget is built to be used when user wants to see what the Songs inside some pages. 
/// Apply effects to the song being played under certain conditions. 
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
    /// Decide whether to display the rotating disc and the wavy sound effect. 
    final bool isPlaying;

    const SongList({
        super.key,
        required this.currentPlaylist, 
        required this.currentSong,
        required this.onSongTap,
        this.onSongButtonTap,
        this.bottomPadding = 180,
        this.isPlaying = false,
    });
        
    /// Projects the song list and highlight what song is currently being play. 
    /// 
    /// Highlight is only enable when the song playing originates from BOTH the active playlist and the current playlist. 
    @override
    Widget build(BuildContext context) {
        return currentPlaylist.getCurrentPlaylistSongs().isEmpty 
            ? const _NoSongsPlaceholder()
            : _SongsListView(
                context: context,
                currentPlaylist: currentPlaylist,
                currentSong: currentSong,
                onSongTap: onSongTap,
                onSongButtonTap: onSongButtonTap,
                bottomPadding: bottomPadding,
                isPlaying: isPlaying,
            );
    }
}

class _SongsListView extends StatelessWidget {
    final BuildContext context;
    final SongsPlaylist currentPlaylist;
    final Song? currentSong;
    final Function(Song) onSongTap;
    final Function(Song)? onSongButtonTap;
    final double bottomPadding;
    final bool isPlaying;

    const _SongsListView({
        required this.context,
        required this.currentPlaylist,
        required this.currentSong,
        required this.onSongTap,
        required this.onSongButtonTap,
        required this.bottomPadding,
        required this.isPlaying,
    });

    @override
    Widget build(BuildContext context) {
        // The name of the playlist are guaranteed to be unique => use as our identifier.
        final bool isSamePlaylist = (currentPlaylist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName);
        return CustomScrollView(
            slivers: [
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        childCount: currentPlaylist.getCurrentPlaylistSongs().length,
                        (context, index) {
                            final song = currentPlaylist.getCurrentPlaylistSongs()[index];
                            bool isSelected = (song.assetPath == (currentSong?.assetPath)) && isSamePlaylist;
                            return _SongListItem(
                                song: song,
                                isSelected: isSelected,
                                isPlaying: isPlaying,
                                onSongTap: onSongTap,
                                onSongButtonTap: onSongButtonTap,
                            );
                        }
                    ) 
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + bottomPadding)),
            ],
        );
    }
}

class _SongListItem extends StatelessWidget {
    final Song song;
    final bool isSelected;
    final bool isPlaying;
    final Function(Song) onSongTap;
    final Function(Song)? onSongButtonTap;

    const _SongListItem({
        required this.song,
        required this.isSelected,
        required this.isPlaying,
        required this.onSongTap,
        required this.onSongButtonTap,
    });

    @override
    Widget build(BuildContext context) {
        /// Song will only rotate if it is both playing and selected but we will still display the disc if either playing or selected is true
        /// For example: song is selected, but user pause => the disc is in rotation, just happen to not be moving. 
        final bool shouldRotate = isSelected && isPlaying;
        
        final selectedBorder = BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha:0.3)),
                );

        return CustomListTile(
            title: song.title,
            subtitle: song.artist ?? "Unknown",
            onTap: () => onSongTap(song),
            selected: isSelected,
            alpha: isSelected ? 0.15 : 0.09,
            selectedColor: Theme.of(context).colorScheme.onPrimary,
            decoration: selectedBorder,
            /// Rotating effect. 
            leading: shouldRotate || isSelected
                ? RotatingDisc(
                    isPlaying: shouldRotate,
                    child: AlbumArt(
                      albumArtBytes: song.albumArtBytes,
                      artWidth: 30,
                      artHeight: 30,
                    ),
                  )
                : AlbumArt(
                    albumArtBytes: song.albumArtBytes,
                    artWidth: 30,
                    artHeight: 30,
                  ),
            /// Trailing, including the sound wave. 
            trailing: _TrailingButtons(
                onSongButtonTap: onSongButtonTap,
                song: song,
                isSelected: isSelected,
                isPlaying: isPlaying,
            ),
        );
    }
}

class _TrailingButtons extends StatelessWidget {
    final Function(Song)? onSongButtonTap;
    final Song song;
    final bool? isSelected; 
    final bool? isPlaying; 

    const _TrailingButtons({
        required this.onSongButtonTap,
        required this.song,
        required this.isSelected, 
        required this.isPlaying,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            // If not provided the correct function, then we dont display the button.
            mainAxisSize: MainAxisSize.min,
            children: [
                // Playing wave effect (to the left of the delete button).
                if ((isSelected != null && isSelected == true) && (isPlaying != null && isPlaying == true))
                    Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: SpinKitWave(
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 16,
                            ),
                        ),
                    ),
                // Delete button, if provided. 
                if (onSongButtonTap != null)
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        onPressed: () => onSongButtonTap!(song),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Delete Song", 
                    )
            ]
        );
    }
}

class _NoSongsPlaceholder extends StatelessWidget {
    const _NoSongsPlaceholder();

    @override
    Widget build(BuildContext context) {
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
}