import 'package:flutter/material.dart';

import 'playlist_grid_tile.dart';
import 'playlists_list.dart';
import '../entities/song_playlist.dart';

/// A grid view of the playlist, 2 items per row and spacing in between. 
class PlaylistGridView extends StatelessWidget {
    final BuildContext context;
    final List<SongsPlaylist> playlists;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo;
    /// We know from the caller that the bottom padding by default is 180, so it is non-nullable. 
    final double bottomPadding;
    
    const PlaylistGridView({
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
                SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                            childCount: playlists.length,
                            (context, index) {
                                final playlist = playlists[index];
                                return PlaylistGridTile(
                                    playlist: playlist,
                                    onPlaylistTap: onPlaylistTap,
                                    onPlaylistButtonTap: onPlaylistButtonTap,
                                    onPlaylistButtonTapTwo: onPlaylistButtonTapTwo,
                                );
                            },
                            
                        ),
                    ),
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + bottomPadding)),
            ],
        );
    }
}