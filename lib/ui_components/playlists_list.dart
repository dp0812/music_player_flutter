import 'package:flutter/material.dart';
import 'package:music_player/ui_components/custom_list_tile.dart';

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
    /// Avoid dock (in compact mode) from preventing user click on the last item of the list. 
    final double bottomPadding;
    
    const PlaylistsList({
        super.key, 
        required this.onPlaylistTap, 
        this.onPlaylistButtonTap,
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
                    return _buildPlaylistsIfAvailable(context, playlists);
                },
            ),
        );
    }

    /// If there exist some playlist => provide list of playlists. Otherwise provide placeholder.  
    Widget _buildPlaylistsIfAvailable(BuildContext context , List<SongsPlaylist> playlists){
        return playlists.isEmpty
            ? _buildPlaceholderIfNoPlaylistFound()
            : _buildPlaylistLists(context, playlists);
    }

    Widget _buildPlaylistLists(BuildContext context ,List<SongsPlaylist> playlists){
        return CustomScrollView(
            slivers: [
                SliverList(delegate: SliverChildBuilderDelegate(
                    childCount: playlists.length, 
                    (context, index){
                        final playlist = playlists[index];
                        return _customListTile(playlist);
                    }
                )),
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + bottomPadding)),
            ],
        );
    }

    Widget _customListTile(SongsPlaylist playlist){
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
                        Icon(Icons.more_vert), // needs tooltip rework. 
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

    Widget _buildPlaceholderIfNoPlaylistFound(){
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    "No playlists found. Click the 'Add Playlist' button to create one!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                ),
            ),
        );
    }
}