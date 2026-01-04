import 'package:flutter/material.dart';
import 'package:music_player/ui_components/custom_list_tile.dart';

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
    
    const PlaylistsList({
        super.key, 
        required this.onPlaylistTap, 
        this.onPlaylistButtonTap,
        this.onPlaylistButtonTapTwo,
        this.bottomPadding = 180, 
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
                    return playlists.isNotEmpty
                        ? _PlaylistListView(
                            context: context, 
                            playlists: playlists,
                            onPlaylistTap: onPlaylistTap,
                            onPlaylistButtonTap: onPlaylistButtonTap,
                            onPlaylistButtonTapTwo: onPlaylistButtonTapTwo,
                            bottomPadding: bottomPadding,
                        )
                        : PlaceholderContent(displayMessage: "No playlists found in your system. Click the 'Add Playlist' button to create one!");
                },
            ),
        );
    }
}

class _PlaylistListView extends StatelessWidget {
    final BuildContext context;
    final List<SongsPlaylist> playlists;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo;
    /// We know from above that the bottom padding by default is 180, so it is non-nullable. 
    final double bottomPadding;
    
    const _PlaylistListView({
        required this.context, 
        required this.playlists,
        required this.onPlaylistTap,
        this.onPlaylistButtonTap,
        this.onPlaylistButtonTapTwo,
        required this.bottomPadding, 
    });

    @override
    Widget build(BuildContext context) {
        return CustomScrollView(
            slivers: [
                SliverList(delegate: SliverChildBuilderDelegate(
                    childCount: playlists.length, 
                    (context, index){
                        final playlist = playlists[index];
                        return _PlaylistTile(
                            playlist: playlist,
                            onPlaylistTap: onPlaylistTap,
                            onPlaylistButtonTap: onPlaylistButtonTap,
                            onPlaylistButtonTapTwo: onPlaylistButtonTapTwo,
                        );
                    }
                )),
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + bottomPadding)),
            ],
        );
    }
}

/// Custom list tiletile. 
class _PlaylistTile extends StatelessWidget{
    final SongsPlaylist playlist;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo;

    const _PlaylistTile({
        required this.playlist, 
        required this.onPlaylistTap,
        required this.onPlaylistButtonTap, 
        required this.onPlaylistButtonTapTwo
    });

    @override
    Widget build(BuildContext context) {
        return CustomListTile(
            leading: const Icon(Icons.featured_play_list), 
            title: playlist.playlistName, 
            subtitle: "${playlist.songCount} song(s)", 
            onTap: () => onPlaylistTap(playlist),
            trailing: 
                Row(
                    spacing: 2.0,
                    mainAxisSize: MainAxisSize.min,
                    children: [ 
                        Icon(Icons.more_vert),
                        const SizedBox(width: 5,),
                        if (onPlaylistButtonTapTwo != null)
                        IconButton (
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => onPlaylistButtonTapTwo!(playlist),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Rename Playlist", 
                        ),
                        const SizedBox(width: 5,),
                        if (onPlaylistButtonTap != null)
                        IconButton (
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onPlaylistButtonTap!(playlist),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Delete Playlist", 
                        ),
                    ],
                ) 
        );
    }
}