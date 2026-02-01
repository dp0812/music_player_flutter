import 'package:flutter/material.dart';

import 'album_art.dart';
import 'constraints.dart';
import 'custom_grid_tile.dart';
import 'playlist_cover.dart';
import 'playlists_list.dart';
import 'playlist_pop_up_menu.dart';
import '../entities/song_playlist.dart';

/// Define the content of the tile, namely, title, subtitle, exposure of the CD (optional), and the Pop up menu.
/// 
/// Remarks: Use the albumArt of the first song in the current Playlist as the playlist art. 
class PlaylistGridTile extends StatelessWidget{
  
    final SongsPlaylist playlist;   
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    final PlaylistTapCallback? onPlaylistButtonTapTwo;
    final bool isSelected;
    /// Allow the cd to pop up behind. 
    final bool enableDisc; 

    const PlaylistGridTile({
        super.key,
        required this.playlist, 
        required this.onPlaylistTap,
        required this.onPlaylistButtonTap, 
        required this.onPlaylistButtonTapTwo,
        this.isSelected = false,
        this.enableDisc = false,
    });

    @override
    Widget build(BuildContext context) {
        return CustomGridTile(
            leading: Container(
                padding: enableDisc? EdgeInsets.only(right: 20) : EdgeInsets.zero,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(Constraints.artBorderRad),
                    child: PlaylistCover(playlistArt:_dynamicAlbumArt(context), enableDisc: enableDisc,)
                ),
            ),
            title: playlist.playlistName,
            subtitle: "${playlist.songCount} song(s)",
            onTap: () => onPlaylistTap(playlist),
            isSelected: isSelected,
            trailing: PlaylistPopUpMenu(
                playlist: playlist, 
                onRename: onPlaylistButtonTapTwo, 
                onDelete: onPlaylistButtonTap
            ),
        );
    }

    /// The size is set to extremely high value so it can be resize down. 
    /// 
    /// Remarks: The null return is to use the OTHER placeholder in the CustomGridTile for the playlist, and not the placeholder for the song art itself. 
    Widget? _dynamicAlbumArt(BuildContext context){
        
        if(playlist.firstSong()?.albumArtBytes == null) return null; 
        return AlbumArt(
            albumArtBytes: playlist.firstSong()?.albumArtBytes,
            artHeight: MediaQuery.sizeOf(context).height,
            artWidth: MediaQuery.sizeOf(context).width,
        );
    }
}