import 'package:flutter/material.dart';

import 'playlist_grid_view.dart';
import 'playlist_list_view.dart';
import 'placeholder_content.dart';
import '../entities/song_repository.dart';
import '../entities/song_playlist.dart';

typedef PlaylistTapCallback = void Function(SongsPlaylist playlist);

/// Displays the currently available playlist(s).
/// 
/// Refresh playlist songs count based on listener [playlistNotifier] from [SongRepository]. 
/// Include a bottom padding just enough for the dock in compact mode when scroll to the bottom of the list. 
class PlaylistsList extends StatelessWidget {
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo; 
    /// Avoid dock (in compact mode) from preventing user click on the last item of the list. 
    final double bottomPadding;
    final bool viewGMode;
    
    const PlaylistsList({
        super.key, 
        required this.onPlaylistTap, 
        this.onPlaylistButtonTap,
        this.onPlaylistButtonTapTwo,
        this.bottomPadding = 180,
        this.viewGMode = false,  
    });

    /// Projects all available playlists from the [SongRepository].
    ///  
    /// Use the change notifier [playlistNotifier] from [SongRepository] to update its view everytime a change to the data happen (not just identity change).
    @override
    Widget build(BuildContext context) {
        // Warning: this is here to ensure that the playlist page state has the correct numbers of song after adding songs. 
        return Scaffold(
            body: AnimatedBuilder(
                animation: SongRepository.playlistNotifier,
                builder: (context, child) {
                    final List<SongsPlaylist> playlists = 
                        SongRepository.playlistNotifier.playlists.values.toList();
                    
                    /// If there exist some playlist => provide list of playlists. Otherwise provide placeholder. 
                    return _correctViewMode(playlists, context);

                },
            ),
        );
    }

    Widget _correctViewMode(List<SongsPlaylist> playlists, BuildContext context) {
        if (playlists.isEmpty) {
            return PlaceholderContent(
                displayMessage: "No playlists found in your system. Click the 'Add Playlist' button to create one!"
            );
        }
        
        if (viewGMode) {
            return PlaylistGridView(
                context: context, 
                playlists: playlists, 
                onPlaylistTap: onPlaylistTap, 
                onPlaylistButtonTap: onPlaylistButtonTap,
                onPlaylistButtonTapTwo: onPlaylistButtonTapTwo,
                bottomPadding: bottomPadding
            );
        }
        
        return PlaylistListView(
            context: context, 
            playlists: playlists,
            onPlaylistTap: onPlaylistTap,
            onPlaylistButtonTap: onPlaylistButtonTap,
            onPlaylistButtonTapTwo: onPlaylistButtonTapTwo,
            bottomPadding: bottomPadding,
        );
        
    }
}