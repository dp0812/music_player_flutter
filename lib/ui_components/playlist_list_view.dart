import 'package:flutter/material.dart';


import 'playlist_list_tile.dart';
import 'playlists_list.dart';
import '../entities/song_playlist.dart';

/// One list tile per row and all info and buttons are on the tile. 
class PlaylistListView extends StatelessWidget {
    final BuildContext context;
    final List<SongsPlaylist> playlists;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo; 
    /// We know from the caller that the bottom padding by default is 180, so it is non-nullable.
    final double bottomPadding;
    
    const PlaylistListView({
        super.key,
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
                        return PlaylistListTile(
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