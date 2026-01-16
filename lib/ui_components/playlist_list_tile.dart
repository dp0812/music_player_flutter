import 'package:flutter/material.dart';

import 'playlists_list.dart';
import 'custom_list_tile.dart';
import '../entities/song_playlist.dart';

/// Define the content of the tile, namely, title, subtitle, and the actions that can be done (rename and delete).
class PlaylistListTile extends StatelessWidget{
  
    final SongsPlaylist playlist;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo;

    const PlaylistListTile({
        super.key,
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
                        const SizedBox(width: 3,),
                        if (onPlaylistButtonTapTwo != null)
                        IconButton (
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => onPlaylistButtonTapTwo!(playlist),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Rename Playlist", 
                        ),
                        if (onPlaylistButtonTap != null)
                        IconButton (
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onPlaylistButtonTap!(playlist),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Delete Playlist", 
                        ),
                    ],
                ), 
        );
    }

}